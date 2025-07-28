import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/visite_request.dart';
import '../utils/secure_storage.dart';
class ApiService {

Future<Visite> modifierStatutVisite({
  required int visiteId,
  required String nouveauStatut, // Exemple : "REALISEE", "ANNULEE", etc.
}) async {
  final url = Uri.parse('$baseUrl/visites/$visiteId/statut?statut=$nouveauStatut');

  final response = await http.put(
    url,
    headers: await _headers(), // 🔁 headers centralisés (avec ou sans token)
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return Visite.fromJson(data);
  } else {
    throw Exception('Erreur lors de la modification du statut : ${response.body}');
  }
}

 Future<List<Visite>> getPlanificationVisites() async {
  final response = await http.post(
    Uri.parse('$baseUrl/visites/planification-auto'),
    headers: await _headers(),
  );

  if (response.statusCode == 200) {
    final List<dynamic> body = json.decode(response.body);
    final visites = body.map((jsonItem) => Visite.fromJson(jsonItem)).toList();
    return visites;
  } else {
    throw Exception('Erreur lors du chargement de la planification des visites');
  }
}

  Future<Map<String, String>> _headers() async {
    final token = await SecureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Visite>> getProchainesVisitesCritiques() async {
  final response = await http.get(
    Uri.parse('$baseUrl/visites/mes-visites'),
    headers: await _headers(),
  );
  if (response.statusCode == 200) {
    List<dynamic> body = json.decode(response.body);
    // Optionnel: print(body); // pour voir tout le JSON (attention long)

    List<Visite> visites = body.map((dynamic item) => Visite.fromJson(item)).toList();
    return visites;
  } else {
    throw Exception('Erreur lors du chargement des visites');
  }
}

 
}


