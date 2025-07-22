import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/visite_request.dart';

class ApiService {
  // Méthode GET pour récupérer les visites critiques
  Future<List<Visite>> getProchainesVisitesCritiques() async {
    final url = Uri.parse('$baseUrl/visites/prochaines-visites-critiques');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      List<Visite> visites =
          body.map((dynamic item) => Visite.fromJson(item)).toList();
      return visites;
    } else {
      throw Exception('Erreur lors du chargement des visites');
    }
  }

  // Méthode POST générique statique
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erreur API : ${response.body}");
    }
  }
}
