import 'dart:convert';
import 'package:http/http.dart' as http;

class FreeLLMService {
  static const String defaultBaseUrl = 'http://127.0.0.1:31415/v1';
  static const String defaultApiKey =
      'freellmapi-b034f7466b480649850d74c3e6df9652e5ed995c69ffed9d';

  final String baseUrl;
  final String apiKey;

  FreeLLMService({
    this.baseUrl = defaultBaseUrl,
    this.apiKey = defaultApiKey,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

  /// Fetch all active models supported by FreeLLMAPI
  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    final response = await http.get(
      Uri.parse('$baseUrl/models'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = (data['data'] as List).cast<Map<String, dynamic>>();
      return list.where((m) => m['available'] == true || m['execution_status'] == 'ready').toList();
    } else {
      throw Exception('Failed to load FreeLLMAPI models: ${response.body}');
    }
  }

  /// Request a chat completion
  Future<String> chatCompletion({
    required List<Map<String, String>> messages,
    String model = 'auto',
    double temperature = 0.7,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: _headers,
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': temperature,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] ?? '';
    } else {
      throw Exception('FreeLLMAPI Error (${response.statusCode}): ${response.body}');
    }
  }

  /// Simple one-shot prompt helper
  Future<String> ask(String prompt, {String model = 'auto'}) async {
    return chatCompletion(
      messages: [
        {'role': 'user', 'content': prompt}
      ],
      model: model,
    );
  }
}
