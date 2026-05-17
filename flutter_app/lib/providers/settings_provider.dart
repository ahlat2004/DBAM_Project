import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/llm_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _useOllama = true;
  String _ollamaUrl = 'http://localhost:11434';
  String _ollamaModel = 'qwen2.5-coder';
  String _geminiApiKey = '';
  String _geminiModel = 'gemini-2.5-flash';
  bool _isTesting = false;
  String _testResult = '';

  bool get useOllama => _useOllama;
  bool get useGemini => !_useOllama;
  String get ollamaUrl => _ollamaUrl;
  String get ollamaModel => _ollamaModel;
  String get geminiApiKey => _geminiApiKey;
  String get geminiModel => _geminiModel;
  bool get isTesting => _isTesting;
  String get testResult => _testResult;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _useOllama = prefs.getString('engine') != 'gemini';
    _ollamaUrl = prefs.getString('ollama_url') ?? 'http://localhost:11434';
    _ollamaModel = prefs.getString('ollama_model') ?? 'qwen2.5-coder';
    _geminiApiKey = prefs.getString('gemini_api_key') ?? '';
    _geminiModel = prefs.getString('gemini_model') ?? 'gemini-2.5-flash';
    notifyListeners();
  }

  void setEngine(bool useOllama) {
    _useOllama = useOllama;
    notifyListeners();
  }

  void setOllamaUrl(String v) { _ollamaUrl = v; notifyListeners(); }
  void setOllamaModel(String v) { _ollamaModel = v; notifyListeners(); }
  void setGeminiApiKey(String v) { _geminiApiKey = v; notifyListeners(); }
  void setGeminiModel(String v) { _geminiModel = v; notifyListeners(); }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('engine', _useOllama ? 'ollama' : 'gemini');
    await prefs.setString('ollama_url', _ollamaUrl);
    await prefs.setString('ollama_model', _ollamaModel);
    await prefs.setString('gemini_api_key', _geminiApiKey);
    await prefs.setString('gemini_model', _geminiModel);
    _testResult = '✅ Settings saved.';
    notifyListeners();
  }

  Future<void> testConnection() async {
    _isTesting = true;
    _testResult = '';
    notifyListeners();
    try {
      final svc = LlmService();
      final result = await svc.testConnection(_useOllama);
      _testResult = '✅ Connection OK: $result';
    } catch (e) {
      _testResult = '❌ Failed: $e';
    } finally {
      _isTesting = false;
      notifyListeners();
    }
  }
}
