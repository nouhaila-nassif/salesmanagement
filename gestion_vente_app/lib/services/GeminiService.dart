import 'dart:io' show File;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GeminiService {
  static Future<String> askGemini({
    String? query,
    File? audioFile, // Mobile
    Uint8List? webAudioBytes, // Web
    String? webFileName, // Web
  }) async {
    final dio = Dio();

    try {
      Response response;

      if ((audioFile == null && webAudioBytes == null)) {
        // ✅ Cas uniquement texte → /ask-json
        response = await dio.post(
          "http://localhost:8080/api/ia/ask-json",
          data: {"query": query},
          options: Options(contentType: "application/json"),
        );
      } else {
        // ✅ Cas avec fichier audio → /ask-multipart
        final formData = FormData();

        if (query != null && query.isNotEmpty) {
          formData.fields.add(MapEntry("query", query));
        }

        if (!kIsWeb && audioFile != null) {
          formData.files.add(MapEntry(
            "audioFile",
            await MultipartFile.fromFile(audioFile.path),
          ));
        }

        if (kIsWeb && webAudioBytes != null && webFileName != null) {
          formData.files.add(MapEntry(
            "audioFile",
            MultipartFile.fromBytes(webAudioBytes, filename: webFileName),
          ));
        }

        response = await dio.post(
          "http://localhost:8080/api/ia/ask-multipart",
          data: formData,
          options: Options(contentType: "multipart/form-data"),
        );
      }

      return response.data["result"] ?? "Pas de réponse IA.";
    } catch (e) {
      return "Erreur lors de l'appel à l'IA : $e";
    }
  }
}
