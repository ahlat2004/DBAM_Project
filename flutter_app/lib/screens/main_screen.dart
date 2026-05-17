import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/main_provider.dart';
import '../models/app_models.dart';
import 'widgets.dart';
import 'visualizer_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: kPrimary, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.storage, color: kTextBright, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('AI Database Analyzer',
              style: TextStyle(
                  color: kTextBright,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('SQL Server',
                style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF94A3B8)),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: kBorder, height: 1),
        ),
      ),
      body: Consumer<MainProvider>(
        builder: (context, m, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStep(context, m),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep(BuildContext context, MainProvider m) {
    switch (m.step) {
      case WizardStep.connection:
        return const _ConnectionStep(key: ValueKey('conn'));
      case WizardStep.filters:
        return const _FiltersStep(key: ValueKey('filters'));
      case WizardStep.schemaPreview:
        return const _SchemaPreviewStep(key: ValueKey('schema'));
      case WizardStep.topics:
        return const _TopicsStep(key: ValueKey('topics'));
      case WizardStep.analysisProgress:
        return const _AnalysisProgressStep(key: ValueKey('progress'));
    }
  }
}

// ═══════════════════════════════════════
// STEP 1 – Connection (SQL Server Only)
// ═══════════════════════════════════════
class _ConnectionStep extends StatefulWidget {
  const _ConnectionStep({super.key});
  @override
  State<_ConnectionStep> createState() => _ConnectionStepState();
}

class _ConnectionStepState extends State<_ConnectionStep> {
  late final TextEditingController _serverCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;

  @override
  void initState() {
    super.initState();
    final m = context.read<MainProvider>();
    _serverCtrl = TextEditingController(text: m.serverAddress);
    _portCtrl = TextEditingController(text: m.port);
    _userCtrl = TextEditingController(text: m.username);
    _passCtrl = TextEditingController(text: m.password);
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<MainProvider>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _StepHeader(step: 1, title: 'SQL Server Connection'),
      const SizedBox(height: 20),
      appCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // SQL Server badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1E3A5F)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.dns, color: Color(0xFF60A5FA), size: 16),
            SizedBox(width: 8),
            Text('Microsoft SQL Server',
                style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                fieldLabel('SERVER ADDRESS'),
                appTextField(_serverCtrl, 'localhost or IP address',
                    onChanged: (v) => m.serverAddress = v),
              ])),
          const SizedBox(width: 16),
          SizedBox(
              width: 140,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fieldLabel('PORT'),
                    appTextField(_portCtrl, '1433',
                        onChanged: (v) => m.port = v),
                  ])),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                fieldLabel('USERNAME'),
                appTextField(_userCtrl, 'sa', onChanged: (v) => m.username = v),
              ])),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                fieldLabel('PASSWORD'),
                appTextField(_passCtrl, '••••••••',
                    isObscure: true, onChanged: (v) => m.password = v),
              ])),
        ]),
        const SizedBox(height: 20),
        if (m.errorMessage.isNotEmpty) _ErrorBanner(m.errorMessage),
        SizedBox(
          width: double.infinity,
          child: primaryBtn(
            m.isBusy ? 'Connecting...' : 'Connect & Fetch Databases',
            m.isBusy
                ? null
                : () {
                    m.serverAddress = _serverCtrl.text;
                    m.port = _portCtrl.text;
                    m.username = _userCtrl.text;
                    m.password = _passCtrl.text;
                    m.connect();
                  },
          ),
        ),
        if (m.isBusy)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator(color: kPrimary)),
          ),
      ])),
    ]);
  }
}

// ═══════════════════════════════════════
// STEP 2 – Filters
// ═══════════════════════════════════════
class _FiltersStep extends StatefulWidget {
  const _FiltersStep({super.key});
  @override
  State<_FiltersStep> createState() => _FiltersStepState();
}

class _FiltersStepState extends State<_FiltersStep> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<MainProvider>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _StepHeader(step: 2, title: 'Scope & Components'),
      const SizedBox(height: 20),
      appCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        fieldLabel('TARGET DATABASE'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          child: DropdownButton<String>(
            value: m.selectedDatabase,
            dropdownColor: kSurface,
            isExpanded: true,
            underline: const SizedBox(),
            style: const TextStyle(color: kTextBright, fontSize: 14),
            items: m.databases
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) {
              if (v != null) m.selectDatabase(v);
            },
          ),
        ),
        const SizedBox(height: 16),
        fieldLabel('INCLUDE COMPONENTS'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ...m.components.map((c) => SizedBox(
                width: 180,
                child: appCheckbox(
                    c.isSelected, c.name, () => m.toggleComponent(c)),
              )),
          SizedBox(
            width: 220,
            child: appCheckbox(m.sampleData.isSelected, m.sampleData.name,
                () => m.toggleSampleData()),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      fieldLabel('TABLES TO ANALYZE'),
                      Text(m.selectedTableText,
                          style: const TextStyle(
                              color: kPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ]),
                const SizedBox(height: 4),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => m.searchQuery = v,
                  style: const TextStyle(color: kTextBright, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search tables...',
                    hintStyle: const TextStyle(color: kMuted),
                    prefixIcon:
                        const Icon(Icons.search, color: kMuted, size: 18),
                    filled: true,
                    fillColor: kBg,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: kBorder)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ])),
          const SizedBox(width: 12),
          Align(
              alignment: Alignment.bottomCenter,
              child: secondaryBtn('Toggle All', m.toggleAllTables)),
        ]),
        const SizedBox(height: 8),
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          child: m.isBusy
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: m.filteredTables.length,
                  itemBuilder: (_, i) {
                    final t = m.filteredTables[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: appCheckbox(
                          t.isSelected, t.name, () => m.toggleTable(t)),
                    );
                  },
                ),
        ),
        const SizedBox(height: 20),
        if (m.errorMessage.isNotEmpty) _ErrorBanner(m.errorMessage),
        Row(children: [
          Expanded(child: secondaryBtn('← Back', m.backToConnection)),
          const SizedBox(width: 12),
          Expanded(
              child: primaryBtn(
            m.isBusy ? 'Extracting...' : 'Extract Schema Structure',
            m.isBusy ? null : m.extractSchema,
          )),
        ]),
      ])),
    ]);
  }
}

// ═══════════════════════════════════════
// STEP 3 – Schema Preview
// ═══════════════════════════════════════
class _SchemaPreviewStep extends StatelessWidget {
  const _SchemaPreviewStep({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<MainProvider>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _StepHeader(step: 3, title: 'Schema Context Preview'),
      const SizedBox(height: 20),
      appCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Structural Payload:',
              style: TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(m.schemaStatsText,
                style: TextStyle(
                  color: m.schemaTokensExceeded ? Colors.red.shade300 : kText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                )),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Text(m.extractedJsonSchema,
                style: const TextStyle(
                    color: kText, fontSize: 12, fontFamily: 'monospace')),
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: secondaryBtn('Start Over', m.startOver)),
          const SizedBox(width: 8),
          Expanded(
              child: secondaryBtn('Export TXT', () async {
            final path = await m.exportSchemaTxt();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Saved to: $path'),
                  backgroundColor: const Color(0xFF064E3B)));
            }
          })),
          const SizedBox(width: 8),
          Expanded(
              child: secondaryBtn('Visualize', () {
            final code = m.getMermaidCode();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => VisualizerScreen(
                        mermaidCode: code, jsonSchema: m.extractedJsonSchema)));
          })),
          const SizedBox(width: 8),
          Expanded(child: primaryBtn('Approve →', m.approveSchema)),
        ]),
      ])),
    ]);
  }
}

// ═══════════════════════════════════════
// STEP 4 – Topics
// ═══════════════════════════════════════
class _TopicsStep extends StatefulWidget {
  const _TopicsStep({super.key});
  @override
  State<_TopicsStep> createState() => _TopicsStepState();
}

class _TopicsStepState extends State<_TopicsStep> {
  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<MainProvider>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _StepHeader(step: 4, title: 'DBA Analysis Configuration'),
      const SizedBox(height: 20),
      appCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          secondaryBtn('Toggle All Topics', m.toggleAllTopics),
          const Spacer(),
          Text(m.selectedTopicText,
              style: const TextStyle(
                  color: kPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: m.topics.length,
            itemBuilder: (_, i) {
              final t = m.topics[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Expanded(
                      child: appCheckbox(
                          t.isSelected, t.title, () => m.toggleTopic(t))),
                  if (t.isCustom)
                    IconButton(
                      icon:
                          const Icon(Icons.close, size: 16, color: Colors.red),
                      onPressed: () => m.removeTopic(t),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: appTextField(
                  _customCtrl, 'Add a custom DBA analysis prompt...',
                  onChanged: (v) => m.customTopicText = v)),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              m.addCustomTopic(_customCtrl.text);
              _customCtrl.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kMuted,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Add Prompt',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: kTextBright)),
          ),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: secondaryBtn('← Back', m.backToSchema)),
          const SizedBox(width: 12),
          Expanded(child: primaryBtn('Run DBA Analysis', m.startAnalysis)),
        ]),
      ])),
    ]);
  }
}

// ═══════════════════════════════════════
// STEP 5 – Analysis Progress
// ═══════════════════════════════════════
class _AnalysisProgressStep extends StatelessWidget {
  const _AnalysisProgressStep({super.key});

  Color _statusColor(AnalysisStatus s) {
    switch (s) {
      case AnalysisStatus.completed:
        return Colors.green.shade400;
      case AnalysisStatus.processing:
        return kPrimary;
      case AnalysisStatus.error:
        return Colors.red.shade400;
      default:
        return kMuted;
    }
  }

  String _statusLabel(AnalysisStatus s) {
    switch (s) {
      case AnalysisStatus.completed:
        return '✓ Done';
      case AnalysisStatus.processing:
        return '⏳ Running';
      case AnalysisStatus.error:
        return '✗ Error';
      default:
        return '○ Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<MainProvider>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _StepHeader(step: 5, title: 'DBA Analysis in Progress'),
      const SizedBox(height: 20),
      appCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'The AI is analyzing your SQL Server database against each DBA topic independently.',
          style: TextStyle(color: kMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: m.analysisQueue.length,
            itemBuilder: (_, i) {
              final t = m.analysisQueue[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  SizedBox(
                    width: 80,
                    child: Text(_statusLabel(t.status),
                        style: TextStyle(
                            color: _statusColor(t.status),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text(t.title,
                        style: const TextStyle(color: kText, fontSize: 13)),
                  ),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (m.isAnalysisRunning)
          const Center(child: CircularProgressIndicator(color: kPrimary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          child: Text(m.currentTaskText,
              style: const TextStyle(
                  color: kText, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        if (!m.isAnalysisRunning && m.lastPdfPath.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: primaryBtn('Start New Analysis', m.startOver),
          ),
        ],
      ])),
    ]);
  }
}

// ═══════════════════════════════════════
// Shared sub-widgets
// ═══════════════════════════════════════
class _StepHeader extends StatelessWidget {
  final int step;
  final String title;
  const _StepHeader({required this.step, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: kPrimary, borderRadius: BorderRadius.circular(8)),
        child: Center(
            child: Text('$step',
                style: const TextStyle(
                    color: kTextBright,
                    fontWeight: FontWeight.bold,
                    fontSize: 14))),
      ),
      const SizedBox(width: 12),
      Text(title,
          style: const TextStyle(
              color: kTextBright, fontSize: 20, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.white, fontSize: 13))),
      ]),
    );
  }
}
