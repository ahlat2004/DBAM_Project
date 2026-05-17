import 'dart:convert';
import '../models/app_models.dart';
import 'package:mssql_connection/mssql_connection.dart';

class DbSchemaService {
  // ──────────────────────────────────────────────
  // Get Databases
  // ──────────────────────────────────────────────
  Future<List<String>> getDatabases(Map<String, dynamic> params) async {
    return _mssqlQuery(
      params,
      "SELECT name FROM sys.databases WHERE state = 0 AND name NOT IN ('master', 'tempdb', 'model', 'msdb') ORDER BY name",
      null,
    ).then((rows) => rows.map((r) => r['name'].toString()).toList());
  }

  // ──────────────────────────────────────────────
  // Get Tables
  // ──────────────────────────────────────────────
  Future<List<String>> getTables(Map<String, dynamic> params) async {
    return _mssqlQuery(
      params,
      "SELECT name FROM sys.tables WHERE type = 'U' ORDER BY name",
      params['database'],
    ).then((rows) => rows.map((r) => r['name'].toString()).toList());
  }

  // ──────────────────────────────────────────────
  // Extract Full Schema as JSON
  // ──────────────────────────────────────────────
  Future<String> extractSchemaAsJson(
      Map<String, dynamic> params, SchemaFilterConfig filter) async {
    final schema = <String, dynamic>{};

    // Tables + Columns (enriched with nullability & identity)
    final colRows = await _mssqlQuery(
      params,
      "SELECT t.name AS TABLE_NAME, c.name AS COLUMN_NAME, ty.name AS DATA_TYPE, "
      "c.max_length, c.is_nullable, c.is_identity, "
      "OBJECT_DEFINITION(c.default_object_id) AS default_value "
      "FROM sys.columns c "
      "INNER JOIN sys.tables t ON c.object_id = t.object_id "
      "INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id "
      "ORDER BY t.name, c.column_id",
      params['database'],
    );
    final tables = <String, List<Map<String, dynamic>>>{};
    for (final r in colRows) {
      final tName = r['TABLE_NAME'].toString();
      if (!filter.selectedTables.contains(tName)) continue;
      tables.putIfAbsent(tName, () => []);
      tables[tName]!.add({
        'Column': r['COLUMN_NAME'].toString(),
        'Type': r['DATA_TYPE'].toString(),
        'MaxLen': r['max_length'].toString(),
        'Nullable': r['is_nullable'].toString(),
        'Identity': r['is_identity'].toString(),
        'Default': r['default_value']?.toString() ?? '',
      });
    }
    schema['Tables'] = tables;

    // Foreign Keys
    final fkRows = await _mssqlQuery(
      params,
      "SELECT obj.name AS FK_NAME, tab1.name AS [table], col1.name AS [column], "
      "tab2.name AS [referenced_table], col2.name AS [referenced_column] "
      "FROM sys.foreign_key_columns fkc "
      "INNER JOIN sys.objects obj ON obj.object_id = fkc.constraint_object_id "
      "INNER JOIN sys.tables tab1 ON tab1.object_id = fkc.parent_object_id "
      "INNER JOIN sys.columns col1 ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id "
      "INNER JOIN sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id "
      "INNER JOIN sys.columns col2 ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id",
      params['database'],
    );
    schema['ForeignKeys'] = fkRows
        .where((r) => filter.selectedTables.contains(r['table'].toString()))
        .map((r) => {
              'From': r['table'].toString(),
              'FromColumn': r['column'].toString(),
              'To': r['referenced_table'].toString(),
              'ToColumn': r['referenced_column'].toString(),
              'Name': r['FK_NAME'].toString(),
            })
        .toList();

    // Indexes (enriched with type info)
    if (filter.includeIndexes) {
      final idxRows = await _mssqlQuery(
        params,
        "SELECT t.name AS [Table], i.name AS [Index], i.type_desc AS [Type], "
        "i.is_unique AS [IsUnique], i.is_primary_key AS [IsPK] "
        "FROM sys.indexes i "
        "INNER JOIN sys.tables t ON i.object_id = t.object_id "
        "WHERE i.name IS NOT NULL",
        params['database'],
      );
      schema['Indexes'] = idxRows
          .where((r) => filter.selectedTables.contains(r['Table'].toString()))
          .map((r) => {
                'Table': r['Table'].toString(),
                'Name': r['Index'].toString(),
                'Type': r['Type'].toString(),
                'IsUnique': r['IsUnique'].toString(),
                'IsPrimaryKey': r['IsPK'].toString(),
              })
          .toList();
    }

    // Views
    if (filter.includeViews) {
      final vwRows = await _mssqlQuery(
        params,
        "SELECT v.name, m.definition "
        "FROM sys.views v "
        "LEFT JOIN sys.sql_modules m ON v.object_id = m.object_id",
        params['database'],
      );
      schema['Views'] = vwRows
          .map((r) => {
                'Name': r['name'].toString(),
                'Definition': r['definition']?.toString() ?? '',
              })
          .toList();
    }

    // Triggers (WP-2.1 — was missing)
    if (filter.includeTriggers) {
      final trgRows = await _mssqlQuery(
        params,
        "SELECT t.name AS TriggerName, OBJECT_NAME(t.parent_id) AS TableName, "
        "t.is_disabled, te.type_desc AS EventType, "
        "m.definition AS TriggerBody "
        "FROM sys.triggers t "
        "INNER JOIN sys.trigger_events te ON t.object_id = te.object_id "
        "LEFT JOIN sys.sql_modules m ON t.object_id = m.object_id "
        "WHERE t.is_ms_shipped = 0 AND t.parent_id != 0",
        params['database'],
      );
      schema['Triggers'] = trgRows
          .where((r) => filter.selectedTables.contains(r['TableName'].toString()))
          .map((r) => {
                'Name': r['TriggerName'].toString(),
                'Table': r['TableName'].toString(),
                'Event': r['EventType'].toString(),
                'Disabled': r['is_disabled'].toString(),
                'Body': r['TriggerBody']?.toString() ?? '',
              })
          .toList();
    }

    // Stored Procedures (WP-2.2 — was missing)
    if (filter.includeSps) {
      final spRows = await _mssqlQuery(
        params,
        "SELECT p.name AS ProcName, par.name AS ParamName, "
        "ty.name AS ParamType, par.max_length AS ParamMaxLen, "
        "par.is_output "
        "FROM sys.procedures p "
        "LEFT JOIN sys.parameters par ON p.object_id = par.object_id AND par.parameter_id > 0 "
        "LEFT JOIN sys.types ty ON par.user_type_id = ty.user_type_id "
        "WHERE p.is_ms_shipped = 0",
        params['database'],
      );
      final sps = <String, List<Map<String, dynamic>>>{};
      for (final r in spRows) {
        final name = r['ProcName'].toString();
        sps.putIfAbsent(name, () => []);
        if (r['ParamName'] != null) {
          sps[name]!.add({
            'Param': r['ParamName'].toString(),
            'Type': r['ParamType']?.toString() ?? '',
            'MaxLen': r['ParamMaxLen']?.toString() ?? '',
            'IsOutput': r['is_output']?.toString() ?? 'false',
          });
        }
      }
      schema['StoredProcedures'] = sps;
    }

    // Constraints (WP-2.3 — was missing)
    if (filter.includeConstraints) {
      final cnsRows = await _mssqlQuery(
        params,
        "SELECT OBJECT_NAME(parent_object_id) AS TableName, "
        "name AS ConstraintName, type_desc AS ConstraintType, "
        "OBJECT_DEFINITION(object_id) AS Definition "
        "FROM sys.objects "
        "WHERE type IN ('C','UQ','D','F') AND is_ms_shipped = 0 "
        "ORDER BY OBJECT_NAME(parent_object_id), type_desc",
        params['database'],
      );
      schema['Constraints'] = cnsRows
          .where((r) => filter.selectedTables.contains(r['TableName']?.toString() ?? ''))
          .map((r) => {
                'Table': r['TableName'].toString(),
                'Name': r['ConstraintName'].toString(),
                'Type': r['ConstraintType'].toString(),
                'Definition': r['Definition']?.toString() ?? '',
              })
          .toList();
    }

    // Sample Data
    if (filter.includeSampleData) {
      final samples = <String, dynamic>{};
      for (final table in filter.selectedTables) {
        try {
          final sRows = await _mssqlQuery(
            params,
            'SELECT TOP 3 * FROM [$table] ORDER BY NEWID()',
            params['database'],
          );
          samples[table] = sRows;
        } catch (_) {}
      }
      schema['SampleData'] = samples;
    }

    return const JsonEncoder.withIndent('  ').convert(schema);
  }

  // ──────────────────────────────────────────────
  // Mermaid ER conversion
  // ──────────────────────────────────────────────
  String convertJsonToMermaid(String jsonSchema) {
    final root = jsonDecode(jsonSchema) as Map<String, dynamic>;
    final sb = StringBuffer('erDiagram\n');
    final tables = root['Tables'] as Map<String, dynamic>? ?? {};
    for (final entry in tables.entries) {
      final tableName = entry.key.replaceAll(' ', '_');
      sb.writeln('  $tableName {');
      final cols = entry.value as List<dynamic>;
      for (final col in cols) {
        final colMap = col as Map<String, dynamic>;
        final type = (colMap['Type'] as String? ?? 'varchar').split(' ')[0];
        final colName =
            (colMap['Column'] as String? ?? 'col').replaceAll(' ', '_');
        sb.writeln('    $type $colName');
      }
      sb.writeln('  }');
    }

    final fks = root['ForeignKeys'] as List<dynamic>? ?? [];
    for (final fk in fks) {
      final fkMap = fk as Map<String, dynamic>;
      final from = (fkMap['From'] as String? ?? '').replaceAll(' ', '_');
      final to = (fkMap['To'] as String? ?? '').replaceAll(' ', '_');
      if (from.isNotEmpty && to.isNotEmpty) {
        sb.writeln('  $from }o--|| $to : "FK"');
      }
    }

    return sb.toString();
  }

  // ──────────────────────────────────────────────
  // SQL Server helpers
  // ──────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _mssqlQuery(
      Map<String, dynamic> params, String sql, String? dbName) async {
    final mssqlConnection = MssqlConnection.getInstance();

    final isConnected = await mssqlConnection.connect(
      ip: params['host'] as String,
      port: params['port']?.toString() ?? '1433',
      databaseName: dbName ?? 'master',
      username: params['username'] as String? ?? 'sa',
      password: params['password'] as String? ?? '',
      timeoutInSeconds: 15,
    );

    if (!isConnected) {
      throw Exception('Failed to connect to SQL Server.');
    }

    try {
      final resultStr = await mssqlConnection.getData(sql);
      final json = jsonDecode(resultStr);
      final rows = json['rows'] as List<dynamic>? ?? [];
      return rows.map((e) => e as Map<String, dynamic>).toList();
    } finally {
      await mssqlConnection.disconnect();
    }
  }
}
