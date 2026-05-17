import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LlmService {
  final http.Client _client;

  LlmService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> askGemini(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key') ?? '';
    final modelName =
        prefs.getString('gemini_model') ?? 'gemini-2.5-flash';

    if (apiKey.isEmpty) {
      throw Exception('Gemini API Key is missing. Please check Settings.');
    }

    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey';

    // Retry with exponential backoff for rate limiting (429)
    const maxRetries = 3;
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      final response = await _client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      ).timeout(const Duration(minutes: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      }

      // Rate limited — retry with backoff
      if (response.statusCode == 429 && attempt < maxRetries) {
        final waitSeconds = (attempt + 1) * 15; // 15s, 30s, 45s
        await Future.delayed(Duration(seconds: waitSeconds));
        continue;
      }

      // Non-retryable error or max retries exceeded
      if (response.statusCode == 429) {
        throw Exception(
            'Gemini rate limit exceeded after ${maxRetries + 1} attempts. '
            'Please wait a minute and try again, or reduce the number of topics.');
      }
      throw Exception('Gemini Error ${response.statusCode}: ${response.body}');
    }

    throw Exception('Unexpected error in Gemini request.');
  }

  Future<String> askOllama(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = (prefs.getString('ollama_url') ?? 'http://localhost:11434')
        .replaceAll(RegExp(r'/+$'), '');
    final modelName = prefs.getString('ollama_model') ?? 'qwen2.5-coder';

    final response = await _client.post(
      Uri.parse('$baseUrl/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': modelName,
        'prompt': prompt,
        'stream': false,
        'options': {'num_ctx': 128000},
      }),
    ).timeout(const Duration(minutes: 10));

    if (response.statusCode != 200) {
      throw Exception('Ollama is not responding. Is it running?');
    }

    final data = jsonDecode(response.body);
    return data['response'] as String;
  }

  Future<String> testConnection(bool useOllama) async {
    const testPrompt = 'Reply with exactly: OK';
    if (useOllama) {
      return await askOllama(testPrompt);
    } else {
      return await askGemini(testPrompt);
    }
  }
}
