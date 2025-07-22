import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/Categorie.dart';
import '../utils/secure_storage.dart';

class CategorieService {
  static Future<List<Categorie>> getAllCategories() async {
    final token = await SecureStorage.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Categorie.fromJson(json)).toList();
    } else {
      throw Exception("Erreur chargement catégories");
    }
  }
}
