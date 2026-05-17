import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _ollamaUrlCtrl;
  late TextEditingController _ollamaModelCtrl;
  late TextEditingController _geminiKeyCtrl;
  late TextEditingController _geminiModelCtrl;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>();
    _ollamaUrlCtrl = TextEditingController(text: s.ollamaUrl);
    _ollamaModelCtrl = TextEditingController(text: s.ollamaModel);
    _geminiKeyCtrl = TextEditingController(text: s.geminiApiKey);
    _geminiModelCtrl = TextEditingController(text: s.geminiModel);
  }

  @override
  void dispose() {
    _ollamaUrlCtrl.dispose();
    _ollamaModelCtrl.dispose();
    _geminiKeyCtrl.dispose();
    _geminiModelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, s, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('System Preferences',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFF334155), height: 1),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI Engine Card
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('SELECT AI ENGINE'),
                          const SizedBox(height: 12),
                          Row(children: [
                            _radioBtn('Local (Ollama)', s.useOllama, () {
                              s.setEngine(true);
                            }),
                            const SizedBox(width: 32),
                            _radioBtn('Cloud (Gemini API)', !s.useOllama, () {
                              s.setEngine(false);
                            }),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ollama Config
                    if (s.useOllama)
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('Ollama Configuration'),
                            const SizedBox(height: 16),
                            _fieldLabel('OLLAMA API URL'),
                            _textField(_ollamaUrlCtrl, 'http://localhost:11434',
                                onChanged: s.setOllamaUrl),
                            const SizedBox(height: 12),
                            _fieldLabel('MODEL NAME'),
                            _textField(_ollamaModelCtrl, 'qwen2.5-coder',
                                onChanged: s.setOllamaModel),
                          ],
                        ),
                      ),

                    // Gemini Config
                    if (!s.useOllama)
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('Gemini Configuration'),
                            const SizedBox(height: 16),
                            _fieldLabel('API KEY'),
                            _textField(_geminiKeyCtrl, 'Enter your API key...',
                                isObscure: true, onChanged: s.setGeminiApiKey),
                            const SizedBox(height: 12),
                            _fieldLabel('MODEL NAME'),
                            _textField(_geminiModelCtrl, 'gemini-2.5-flash',
                                onChanged: s.setGeminiModel),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Actions
                    Row(children: [
                      if (s.isTesting)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      const Spacer(),
                      _outlineBtn('Test Connection', s.isTesting ? null : s.testConnection),
                      const SizedBox(width: 12),
                      _primaryBtn('Save Settings', () async {
                        s.setOllamaUrl(_ollamaUrlCtrl.text);
                        s.setOllamaModel(_ollamaModelCtrl.text);
                        s.setGeminiApiKey(_geminiKeyCtrl.text);
                        s.setGeminiModel(_geminiModelCtrl.text);
                        await s.save();
                      }),
                    ]),

                    if (s.testResult.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: s.testResult.startsWith('✅')
                              ? const Color(0xFF064E3B)
                              : const Color(0xFF7F1D1D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(s.testResult,
                            style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: child,
      );

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold));

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600,
          letterSpacing: 0.8));

  Widget _fieldLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
      );

  Widget _textField(TextEditingController ctrl, String hint,
      {bool isObscure = false, required Function(String) onChanged}) =>
      TextField(
        controller: ctrl,
        obscureText: isObscure,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF64748B)),
          filled: true,
          fillColor: const Color(0xFF0F172A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );

  Widget _radioBtn(String label, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Row(children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: selected ? const Color(0xFF2563EB) : const Color(0xFF475569),
                  width: 2),
              color: selected ? const Color(0xFF2563EB) : Colors.transparent,
            ),
            child: selected
                ? const Icon(Icons.circle, size: 8, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14)),
        ]),
      );

  Widget _primaryBtn(String label, VoidCallback? onTap) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  Widget _outlineBtn(String label, VoidCallback? onTap) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF94A3B8),
          side: const BorderSide(color: Color(0xFF334155)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
}
