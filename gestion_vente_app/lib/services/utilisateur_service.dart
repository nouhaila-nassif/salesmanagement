import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/create_utilisateur_request.dart';
import '../models/update_utilisateur_request.dart';
import '../models/utilisateur_response.dart';
import '../models/vendeur_direct_update_dto.dart';
import '../utils/secure_storage.dart';

class UtilisateurService {
  // 🔐 Headers communs
  static Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
static Future<List<UtilisateurResponse>> getVendeursDuSuperviseurConnecte() async {
  final headers = await _getHeaders();
  final response = await http.get(
    Uri.parse('$baseUrl/admin/utilisateurs/superviseurs/vendeurs'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = json.decode(response.body);
    return jsonList.map((json) => UtilisateurResponse.fromJson(json)).toList();
  } else {
    throw Exception('Erreur lors du chargement des vendeurs assignés au superviseur');
  }
}

  // 🔹 Obtenir tous les utilisateurs
// 🔹 Récupérer tous les utilisateurs avec superviseur (vendeurs directs ou autres)
static Future<List<UtilisateurResponse>> getAllUtilisateurs() async {
  final headers = await _getHeaders();

  final response = await http.get(
    Uri.parse('$baseUrl/admin/utilisateurs'), // ← adapte ici selon le vrai endpoint
    headers: headers,
  );

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = json.decode(response.body);
    return jsonList
        .map((json) => UtilisateurResponse.fromJson(json))
        .toList();
  } else {
    throw Exception(
        'Erreur de chargement des utilisateurs (code ${response.statusCode})');
  }
}

 // 🔹 Créer un utilisateur
static Future<UtilisateurResponse> creerUtilisateur(CreateUtilisateurRequest request) async {
  final headers = await _getHeaders();
  final response = await http.post(
    Uri.parse('$baseUrl/admin/utilisateurs/create'),
    headers: headers,
    body: jsonEncode(request.toJson()),
  );

  if (response.statusCode == 201) {
    // Retourner la réponse convertie en objet UtilisateurResponse
    return UtilisateurResponse.fromJson(jsonDecode(response.body));
  } else if (response.statusCode == 400) {
    throw Exception("Données invalides : ${response.body}");
  } else if (response.statusCode == 500) {
    throw Exception("Erreur serveur : ${response.body}");
  } else {
    throw Exception("Erreur création utilisateur : ${response.statusCode} - ${response.body}");
  }
}

  // 🔹 Modifier un utilisateur générique (admin/superviseur/prévendeur)
 static Future<void> modifierUtilisateur(int id, UpdateUtilisateurRequest request) async {
  final headers = await _getHeaders();
  final url = '$baseUrl/admin/utilisateurs/$id';  // Assure-toi que baseUrl contient bien /api si nécessaire


  final response = await http.put(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(request.toJson()),
  );


  if (response.statusCode != 200) {
    throw Exception('Erreur modification utilisateur : ${response.body}');
  }
}

  // 🔹 Modifier un vendeur direct
  static Future<void> modifierVendeurDirect(
      int id, VendeurDirectUpdateDTO vendeurDTO) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/utilisateurs/vendeursdirect/$id'),
      headers: headers,
      body: jsonEncode(vendeurDTO.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur modification vendeur direct : ${response.body}');
    }
  }

  // 🔹 Supprimer un utilisateur
  static Future<void> supprimerUtilisateur(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/utilisateurs/$id'),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Erreur suppression utilisateur : ${response.body}');
    }
  }

// 🔹 Supprimer un vendeur direct
static Future<void> supprimerVendeurDirect(int id) async {
  final headers = await _getHeaders();
  final response = await http.delete(
    Uri.parse('$baseUrl/admin/utilisateurs/vendeursdirect/$id'),
    headers: headers,
  );

  if (response.statusCode != 204) {
    throw Exception('Erreur suppression vendeur direct : ${response.body}');
  }
}

  // 🔹 Récupérer un utilisateur par ID
  static Future<UtilisateurResponse> getUtilisateur(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/utilisateurs/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return UtilisateurResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Utilisateur introuvable');
    }
  }

  // 🔹 Récupérer tous les vendeurs direct
  static Future<List<UtilisateurResponse>> getAllVendeursDirect() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/utilisateurs/vendeursdirect'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList
          .map((json) => UtilisateurResponse.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur chargement vendeurs direct');
    }
  }

  // 🔹 Récupérer tous les pré-vendeurs
  static Future<List<UtilisateurResponse>> getAllPreVendeurs() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/utilisateurs/prevendeurs'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList
          .map((json) => UtilisateurResponse.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur chargement pré-vendeurs');
    }
  }

  // 🔹 Récupérer tous les vendeurs (direct et pré-vendeurs)
  static Future<List<UtilisateurResponse>> getAllVendeurs() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/utilisateurs/vendeurs'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList
          .map((json) => UtilisateurResponse.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur chargement vendeurs');
    }
  }
}
