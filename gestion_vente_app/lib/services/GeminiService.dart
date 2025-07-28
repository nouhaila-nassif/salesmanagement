import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

import '../utils/secure_storage.dart';

class GeminiService {
  static const String baseUrl = "http://localhost:8080/api/ia";

  static Future<Map<String, String>> askGemini({
    String? query,
    File? audioFile, // Mobile
    Uint8List? webAudioBytes, // Web
    String? webFileName, // Web
  }) async {
    final token = await SecureStorage.getToken();

    try {
      http.Response response;

      if ((audioFile == null && webAudioBytes == null)) {
        // Cas texte simple → /ask-json
        final url = Uri.parse('$baseUrl/ask-json');

        response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'query': query}),
        );
      } else {
        // Cas avec audio → /ask-multipart
        final url = Uri.parse('$baseUrl/ask-multipart');

        var request = http.MultipartRequest('POST', url);
        request.headers['Authorization'] = 'Bearer $token';

        if (query != null && query.isNotEmpty) {
          request.fields['query'] = query;
        }

        if (!kIsWeb && audioFile != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'audioFile',
            audioFile.path,
          ));
        }

        if (kIsWeb && webAudioBytes != null && webFileName != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'audioFile',
            webAudioBytes,
            filename: webFileName,
          ));
        }

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          "result": data["result"]?.toString() ?? "Pas de réponse IA.",
          "transcription": data["transcription"]?.toString() ?? "",
        };
      } else {
        return {
          "result": "Erreur serveur : ${response.statusCode}",
          "transcription": "",
        };
      }
    } catch (e) {
      return {
        "result": "Erreur lors de l'appel à l'IA : $e",
        "transcription": "",
      };
    }
  }
}
