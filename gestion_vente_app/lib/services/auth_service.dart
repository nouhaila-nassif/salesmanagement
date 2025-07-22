import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/login_request.dart';
import '../models/utilisateur.dart';
import '../utils/secure_storage.dart';

class AuthService {
  // Connexion : retourne le token et le stocke
  static Future<String> login(LoginRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final token = body['token'];
      if (token == null) {
        throw Exception('Token manquant dans la réponse.');
      }
      await SecureStorage.saveToken(token);
      return token;
    } else {
      throw Exception('Échec de la connexion : ${response.statusCode}');
    }
  }

  static Future<bool> isAdmin() async {
    final role = await SecureStorage.getUserRole();
    return role == "ADMIN";
  }

  // Récupérer l'utilisateur connecté via le token stocké
  static Future<Utilisateur> fetchCurrentUser() async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      throw Exception('Token manquant. Veuillez vous reconnecter.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/utilisateur/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Utilisateur.fromJson(data);
    } else {
      throw Exception(
          'Impossible de récupérer l’utilisateur connecté : ${response.statusCode}');
    }
  }

  // Déconnexion : supprimer le token stocké
  static Future<void> logout() async {
    await SecureStorage.deleteToken();
  }
}
