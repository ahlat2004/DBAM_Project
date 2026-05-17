import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VisualizerScreen extends StatefulWidget {
  final String mermaidCode;
  final String jsonSchema;

  const VisualizerScreen({
    super.key,
    required this.mermaidCode,
    required this.jsonSchema,
  });

  @override
  State<VisualizerScreen> createState() => _VisualizerScreenState();
}

class _VisualizerScreenState extends State<VisualizerScreen> {
  bool _showMermaid = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Schema Visualizer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showMermaid = true),
            child: Text('Mermaid',
                style: TextStyle(
                    color: _showMermaid
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => setState(() => _showMermaid = false),
            child: Text('JSON',
                style: TextStyle(
                    color: !_showMermaid
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy, color: Color(0xFF94A3B8), size: 20),
            tooltip: 'Copy to clipboard',
            onPressed: () {
              final text =
                  _showMermaid ? widget.mermaidCode : widget.jsonSchema;
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${_showMermaid ? "Mermaid" : "JSON"} copied to clipboard'),
                  backgroundColor: const Color(0xFF064E3B),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF334155), height: 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              _showMermaid ? widget.mermaidCode : widget.jsonSchema,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
