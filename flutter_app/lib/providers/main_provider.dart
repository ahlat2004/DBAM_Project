import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../services/db_schema_service.dart';
import '../services/llm_service.dart';
import '../services/pdf_report_service.dart';

enum WizardStep { connection, filters, schemaPreview, topics, analysisProgress }

class MainProvider extends ChangeNotifier {
  final DbSchemaService _dbService = DbSchemaService();
  final LlmService _llmService = LlmService();
  final PdfReportService _pdfService = PdfReportService();

  // ── Wizard state ──────────────────────────────
  WizardStep _step = WizardStep.connection;
  WizardStep get step => _step;

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // ── Connection form (SQL Server only) ─────────
  String serverAddress = 'localhost';
  String port = '1433';
  String username = 'sa';
  String password = '';

  // ── Databases ─────────────────────────────────
  List<String> databases = [];
  String? selectedDatabase;

  // ── Components ────────────────────────────────
  List<ComponentSelection> components = [
    ComponentSelection(name: 'Views'),
    ComponentSelection(name: 'Indexes'),
    ComponentSelection(name: 'Triggers'),
    ComponentSelection(name: 'Stored Procedures'),
    ComponentSelection(name: 'Constraints'),
  ];
  ComponentSelection sampleData =
      ComponentSelection(name: 'Fetch 3 Random Rows per Table', isSelected: false);

  // ── Tables ────────────────────────────────────
  List<TableSelection> tables = [];
  List<TableSelection> filteredTables = [];
  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  set searchQuery(String v) {
    _searchQuery = v;
    _applyTableFilter();
    notifyListeners();
  }

  String get selectedTableText =>
      '${tables.where((t) => t.isSelected).length} / ${tables.length} tables selected';

  // ── Schema ────────────────────────────────────
  String extractedJsonSchema = '';
  String schemaStatsText = '';
  bool schemaTokensExceeded = false;

  // ── Topics ────────────────────────────────────
  List<AnalysisTopic> topics = [];
  String customTopicText = '';

  String get selectedTopicText =>
      '${topics.where((t) => t.isSelected).length} / ${topics.length} topics selected';

  // ── Analysis progress ─────────────────────────
  List<AnalysisTopic> analysisQueue = [];
  bool isAnalysisRunning = false;
  String currentTaskText = 'Starting...';
  String lastPdfPath = '';

  // ─────────────────────────────────────────────
  MainProvider() {
    _loadDefaultTopics();
  }

  // ── Step navigation ──────────────────────────
  void _goTo(WizardStep s) {
    _step = s;
    _errorMessage = '';
    notifyListeners();
  }

  void backToConnection() => _goTo(WizardStep.connection);
  void backToFilters() => _goTo(WizardStep.filters);
  void backToSchema() => _goTo(WizardStep.topics);
  void approveSchema() => _goTo(WizardStep.topics);

  void startOver() {
    databases = [];
    selectedDatabase = null;
    tables = [];
    filteredTables = [];
    extractedJsonSchema = '';
    schemaStatsText = '';
    _searchQuery = '';
    _goTo(WizardStep.connection);
  }

  // ── Connect & fetch databases ─────────────────
  Future<void> connect() async {
    _setBusy(true);
    try {
      final params = _buildParams(null);
      databases = await _dbService.getDatabases(params);
      selectedDatabase = databases.isNotEmpty ? databases.first : null;
      _goTo(WizardStep.filters);
    } catch (e) {
      _setError('Connection failed: $e');
    } finally {
      _setBusy(false);
    }
  }

  // ── Load tables when DB selected ──────────────
  Future<void> selectDatabase(String db) async {
    selectedDatabase = db;
    notifyListeners();
    _setBusy(true);
    try {
      final params = _buildParams(db);
      final names = await _dbService.getTables(params);
      tables = names.map((n) => TableSelection(name: n)).toList();
      filteredTables = List.from(tables);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load tables: $e');
    } finally {
      _setBusy(false);
    }
  }

  // ── Table selection ───────────────────────────
  void toggleAllTables() {
    final allSelected = tables.every((t) => t.isSelected);
    for (final t in tables) {
      t.isSelected = !allSelected;
    }
    notifyListeners();
  }

  void toggleTable(TableSelection t) {
    t.isSelected = !t.isSelected;
    notifyListeners();
  }

  void toggleComponent(ComponentSelection c) {
    c.isSelected = !c.isSelected;
    notifyListeners();
  }

  void toggleSampleData() {
    sampleData.isSelected = !sampleData.isSelected;
    notifyListeners();
  }

  void _applyTableFilter() {
    final q = _searchQuery.toLowerCase();
    filteredTables =
        q.isEmpty ? List.from(tables) : tables.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  // ── Extract schema ────────────────────────────
  Future<void> extractSchema() async {
    if (selectedDatabase == null) return;
    _setBusy(true);
    try {
      final filter = SchemaFilterConfig(
        selectedTables: tables.where((t) => t.isSelected).map((t) => t.name).toList(),
        includeViews: components.firstWhere((c) => c.name == 'Views').isSelected,
        includeIndexes: components.firstWhere((c) => c.name == 'Indexes').isSelected,
        includeTriggers: components.firstWhere((c) => c.name == 'Triggers').isSelected,
        includeSps: components.firstWhere((c) => c.name == 'Stored Procedures').isSelected,
        includeConstraints: components.firstWhere((c) => c.name == 'Constraints').isSelected,
        includeSampleData: sampleData.isSelected,
      );
      final params = _buildParams(selectedDatabase!);
      extractedJsonSchema = await _dbService.extractSchemaAsJson(params, filter);

      final charCount = extractedJsonSchema.length;
      final kb = charCount / 1024.0;
      final tokens = charCount ~/ 4;
      schemaStatsText =
          'Size: ${kb.toStringAsFixed(2)} KB | Chars: $charCount | Est. Tokens: ~$tokens';
      schemaTokensExceeded = tokens > 100000;

      _goTo(WizardStep.schemaPreview);
    } catch (e) {
      _setError('Schema extraction failed: $e');
    } finally {
      _setBusy(false);
    }
  }

  // ── Export TXT ────────────────────────────────
  Future<String> exportSchemaTxt() async {
    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final path = '${dir.path}/Schema_${selectedDatabase ?? "db"}.txt';
    await File(path).writeAsString(extractedJsonSchema);
    return path;
  }

  // ── Mermaid ───────────────────────────────────
  String getMermaidCode() => _dbService.convertJsonToMermaid(extractedJsonSchema);

  // ── Topics ────────────────────────────────────
  void toggleAllTopics() {
    final allSelected = topics.every((t) => t.isSelected);
    for (final t in topics) {
      t.isSelected = !allSelected;
    }
    notifyListeners();
  }

  void toggleTopic(AnalysisTopic t) {
    t.isSelected = !t.isSelected;
    notifyListeners();
  }

  void addCustomTopic(String text) {
    if (text.trim().isEmpty) return;
    topics.add(AnalysisTopic(
      title: 'Custom Prompt',
      prompt: text.trim(),
      isCustom: true,
      isSelected: true,
    ));
    customTopicText = '';
    notifyListeners();
  }

  void removeTopic(AnalysisTopic t) {
    if (t.isCustom) {
      topics.remove(t);
      notifyListeners();
    }
  }

  // ── Run analysis ──────────────────────────────
  Future<void> startAnalysis() async {
    final selected = topics.where((t) => t.isSelected).toList();
    if (selected.isEmpty) return;

    for (final t in selected) {
      t.status = AnalysisStatus.pending;
    }
    analysisQueue = selected;
    isAnalysisRunning = true;
    _goTo(WizardStep.analysisProgress);

    final prefs = await SharedPreferences.getInstance();
    final useOllama = prefs.getString('engine') != 'gemini';
    final sections = <ReportSection>[];
    final fullContent = StringBuffer();

    try {
      for (int i = 0; i < selected.length; i++) {
        final topic = selected[i];
        topic.status = AnalysisStatus.processing;
        currentTaskText =
            'Processing: ${topic.title} (${i + 1}/${selected.length})';
        notifyListeners();

        try {
          final promptWithSchema =
              '${topic.prompt}\n\nSQL Server Database Schema (JSON):\n$extractedJsonSchema';
          final response = useOllama
              ? await _llmService.askOllama(promptWithSchema)
              : await _llmService.askGemini(promptWithSchema);

          sections.add(ReportSection(title: topic.title, content: response));
          fullContent.writeln('--- Section: ${topic.title} ---');
          fullContent.writeln(response);
          fullContent.writeln();
          topic.status = AnalysisStatus.completed;
        } catch (e) {
          topic.status = AnalysisStatus.error;
          sections.add(ReportSection(title: topic.title, content: 'Error: $e'));
        }
        notifyListeners();

        // Small delay between topics to avoid rate limiting
        if (i < selected.length - 1) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      currentTaskText = 'Generating Executive Summary & Action Plan...';
      notifyListeners();

      final agg = fullContent.toString();
      String summaryResp = '';
      String actionResp = '';
      try {
        summaryResp = useOllama
            ? await _llmService.askOllama(
                'You are a Senior SQL Server DBA. Write an Executive Summary based on these database analysis results. '
                'Highlight the most critical findings and their business impact:\n$agg')
            : await _llmService.askGemini(
                'You are a Senior SQL Server DBA. Write an Executive Summary based on these database analysis results. '
                'Highlight the most critical findings and their business impact:\n$agg');
        await Future.delayed(const Duration(seconds: 2));
        actionResp = useOllama
            ? await _llmService.askOllama(
                'You are a Senior SQL Server DBA. Provide a Prioritized Action Plan based on these database analysis results. '
                'Rank items by severity (Critical / High / Medium / Low) and estimated effort:\n$agg')
            : await _llmService.askGemini(
                'You are a Senior SQL Server DBA. Provide a Prioritized Action Plan based on these database analysis results. '
                'Rank items by severity (Critical / High / Medium / Low) and estimated effort:\n$agg');
      } catch (_) {}

      sections.insert(0, ReportSection(title: '1. Executive Summary', content: summaryResp));
      sections.insert(1, ReportSection(title: '2. Prioritized Action Plan', content: actionResp));

      currentTaskText = 'Generating PDF Report...';
      notifyListeners();

      lastPdfPath = await _pdfService.generateReport(sections, selectedDatabase ?? 'database');
      currentTaskText = '✅ Analysis complete. PDF saved to:\n$lastPdfPath';
    } catch (e) {
      currentTaskText = '❌ Error: $e';
    } finally {
      isAnalysisRunning = false;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────
  void _setBusy(bool v) {
    _isBusy = v;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  Map<String, dynamic> _buildParams(String? db) => {
        'host': serverAddress,
        'port': port,
        'username': username,
        'password': password,
        'database': db ?? '',
      };

  // ── 12 DBA-Focused Analysis Topics ────────────
  void _loadDefaultTopics() {
    topics = [
      // ── 🔒 Deadlocks & Blocking ──────────────
      AnalysisTopic(
        title: 'Deadlock Risk Detection & Resolution Strategies',
        prompt:
            'Act as a Senior SQL Server DBA. Analyze the provided database schema (tables, indexes, triggers, stored procedures, and foreign keys) '
            'to identify structural patterns that are prone to causing deadlocks in SQL Server. '
            'Specifically look for: (1) Tables with triggers that modify other tables during DML operations, '
            '(2) Circular foreign key chains that create lock ordering conflicts, '
            '(3) Missing indexes on foreign key columns that force table scans during cascading operations, '
            '(4) Stored procedures that access multiple tables in inconsistent orders. '
            'For each risk found, provide: the specific objects involved, the deadlock scenario explanation, '
            'and a concrete SQL Server resolution strategy (e.g., index creation, query rewrite, NOLOCK hints where safe, or isolation level changes).',
      ),
      AnalysisTopic(
        title: 'Blocking Chain Prevention & Lock Escalation Analysis',
        prompt:
            'Act as a SQL Server Performance Engineer. Examine the schema to identify patterns '
            'that commonly cause long-running blocking chains and lock escalation in SQL Server. '
            'Focus on: (1) Large tables without proper clustered indexes that force table-level locks, '
            '(2) Triggers with complex logic that hold locks for extended periods, '
            '(3) Wide UPDATE patterns on tables with many indexes (each index update extends lock duration), '
            '(4) Missing indexes that force scan-based locks instead of targeted row locks. '
            'Recommend specific isolation level strategies (READ COMMITTED SNAPSHOT, SNAPSHOT), '
            'index improvements, and query patterns to minimize blocking.',
      ),

      // ── 🔍 Index Health ──────────────────────
      AnalysisTopic(
        title: 'Index Health & Missing Index Recommendations',
        prompt:
            'Act as a SQL Server Index Tuning Specialist. Analyze the schema to identify: '
            '(1) Tables with only a clustered index and no non-clustered indexes that likely need covering indexes, '
            '(2) Foreign key columns without supporting indexes (causes slow JOINs and cascade operations), '
            '(3) Wide composite indexes where column order may not match query predicates, '
            '(4) Tables with many columns but few indexes suggesting under-indexing. '
            'For each finding, provide the exact CREATE INDEX statement with INCLUDE columns where appropriate. '
            'Estimate the performance impact (High/Medium/Low).',
      ),
      AnalysisTopic(
        title: 'Duplicate & Overlapping Index Detection',
        prompt:
            'Act as a Database Architecture Auditor. Examine all indexes in the schema to find: '
            '(1) Completely duplicate indexes (same columns in same order), '
            '(2) Overlapping indexes where one is a left-prefix of another, '
            '(3) Indexes that are redundant due to existing UNIQUE or PRIMARY KEY constraints. '
            'Calculate the estimated write overhead and storage waste for each redundant index. '
            'Present results in a table format with columns: Table, Redundant Index, Superseded By, Recommendation (Drop/Merge).',
      ),
      AnalysisTopic(
        title: 'Index Fragmentation & Maintenance Plan',
        prompt:
            'Act as a SQL Server Maintenance Specialist. Based on the table structures, index types, '
            'and estimated data volumes (from sample data if available), predict which indexes are most '
            'susceptible to fragmentation. Consider: (1) Tables with GUID/UNIQUEIDENTIFIER primary keys (random inserts cause page splits), '
            '(2) Heap tables without clustered indexes, (3) Tables with frequent UPDATE operations on indexed columns, '
            '(4) Wide indexes on volatile columns. Provide a complete maintenance plan with: '
            'REORGANIZE vs REBUILD thresholds, recommended schedule, and fill factor recommendations per table.',
      ),

      // ── 🚀 Query Performance ──────────────────
      AnalysisTopic(
        title: 'Query Performance & Execution Plan Anti-Patterns',
        prompt:
            'Act as a Query Optimization Engineer. Based on the schema, construct 3-5 critical query scenarios '
            'that would be common for this database (e.g., multi-table JOINs, aggregation queries, filtered lookups). '
            'For each query: (1) Write the likely SQL, (2) Predict execution plan issues (key lookups, table scans, '
            'implicit conversions, hash match spills), (3) Identify SARGability violations from column data types, '
            '(4) Provide optimized query rewrites and supporting index changes. '
            'Focus specifically on SQL Server execution plan operators and their costs.',
      ),
      AnalysisTopic(
        title: 'Wait Statistics Interpretation & Bottleneck Diagnosis',
        prompt:
            'Act as a SQL Server Performance DBA. Based on the schema structure (table sizes, index patterns, '
            'trigger complexity, stored procedure count), predict the most likely wait types this database would encounter. '
            'For each predicted wait type: (1) Explain what causes it in the context of this schema, '
            '(2) Classify it (CPU / IO / Memory / Lock / Network), '
            '(3) Provide specific remediation steps. '
            'Cover at minimum: CXPACKET, LCK_M_*, PAGEIOLATCH_*, SOS_SCHEDULER_YIELD, ASYNC_NETWORK_IO, and WRITELOG.',
      ),

      // ── 🛡️ Security ──────────────────────────
      AnalysisTopic(
        title: 'Stored Procedure SQL Injection Audit',
        prompt:
            'Act as a Database Security Specialist. Examine all stored procedures in the schema for: '
            '(1) Dynamic SQL construction using string concatenation (EXEC or sp_executesql with unsanitized inputs), '
            '(2) Parameters passed directly into dynamic queries without parameterization, '
            '(3) Procedures that grant excessive permissions or use EXECUTE AS, '
            '(4) Missing input validation patterns. For each vulnerability found, show the risk scenario, '
            'provide a proof-of-concept injection example, and give the secure rewrite using sp_executesql with proper parameterization.',
      ),
      AnalysisTopic(
        title: 'Permission & Role-Based Access Control (RBAC) Audit',
        prompt:
            'Act as a Database Security Auditor. Analyze the schema for RBAC-related structures and identify: '
            '(1) Tables that store sensitive data (PII, credentials, financial data) based on column names and types, '
            '(2) Missing row-level security opportunities, '
            '(3) Tables without audit trail columns (created_at, modified_by), '
            '(4) Stored procedures that should use EXECUTE AS for privilege containment. '
            'Recommend a complete RBAC implementation with database roles, schema-level permissions, and audit mechanisms.',
      ),

      // ── 📋 Maintenance & Recovery ─────────────
      AnalysisTopic(
        title: 'Backup & Disaster Recovery Strategy',
        prompt:
            'Act as a SQL Server Infrastructure DBA. Based on the database schema complexity, table count, '
            'and data characteristics, design a comprehensive backup and disaster recovery strategy. '
            'Include: (1) Full, differential, and transaction log backup schedules with retention policies, '
            '(2) Recovery Point Objective (RPO) and Recovery Time Objective (RTO) recommendations, '
            '(3) Compatibility assessment for Always On Availability Groups or Log Shipping, '
            '(4) Point-in-time recovery procedures. Consider the specific tables and their likely data change rates.',
      ),

      // ── 📋 Documentation ─────────────────────
      AnalysisTopic(
        title: 'Automated Data Dictionary & Schema Documentation',
        prompt:
            'Act as a Technical Writer and SQL Server DBA. Generate a professional Data Dictionary in Markdown format. '
            'For each table: (1) Describe its business purpose based on table/column naming patterns, '
            '(2) List all columns with data type, nullability, and business meaning, '
            '(3) Document all relationships (foreign keys) with referenced tables, '
            '(4) Note any triggers, constraints, or special behaviors. '
            'Include a schema overview section grouping tables by business domain.',
      ),

      // ── 📋 Data Quality ──────────────────────
      AnalysisTopic(
        title: 'Normalization & Data Integrity Audit',
        prompt:
            'Act as a Database Design Auditor. Analyze the schema against normalization principles. '
            'Identify: (1) Violations of Third Normal Form (3NF) — transitive dependencies and repeated data groups, '
            '(2) Tables missing primary keys or using inappropriate primary key types, '
            '(3) Columns that should have CHECK constraints but don\'t (e.g., status columns, email fields), '
            '(4) Missing NOT NULL constraints on business-critical columns, '
            '(5) Orphan records risk from missing or incomplete foreign key constraints. '
            'For each issue, provide the specific ALTER TABLE statement to fix it, with risk assessment for applying the change to production.',
      ),
    ];
    notifyListeners();
  }
}
