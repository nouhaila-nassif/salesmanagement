import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String apiUrl = 'http://localhost:8080/api/ia/ask'; // Remplace par ton IP si besoin

  static Future<String> askGemini(String question) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"query": question}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] ?? 'Pas de réponse.';
    } else {
      throw Exception('Erreur IA : ${response.body}');
    }
  }
}
