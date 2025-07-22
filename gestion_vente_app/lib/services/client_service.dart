import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/client.dart';
import '../utils/secure_storage.dart';

class ClientService {
  /// 🔓 Clients du vendeur connecté
  static Future<List<Client>> getClientsForCurrentUser() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token manquant. Veuillez vous reconnecter.');

    final response = await http.get(
      Uri.parse('$baseUrl/client/mes-clients'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Client.fromJson(json)).toList();
    } else {
      throw Exception('Erreur ${response.statusCode} : impossible de charger les clients.');
    }
  }

  /// 🔐 Tous les clients (Admin)
  static Future<List<Client>> getAllClients() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token manquant.');

    final response = await http.get(
      Uri.parse('$baseUrl/client/mes-clients'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Client.fromJson(json)).toList();
    } else {
      throw Exception('Erreur ${response.statusCode} : échec de récupération des clients.');
    }
  }

 /// 🔐 Un client par ID (Admin / Vendeur)
static Future<Client> getClientById(int id) async {
  final token = await SecureStorage.getToken();
  if (token == null) throw Exception('Token manquant.');

  final response = await http.get(
    Uri.parse('$baseUrl/client/mes-clients/$id'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonMap = json.decode(response.body);
    return Client.fromJson(jsonMap);
  } else if (response.statusCode == 404) {
    throw Exception('Client non trouvé');
  } else if (response.statusCode == 403) {
    throw Exception('Accès refusé');
  } else {
    throw Exception('Erreur ${response.statusCode} : échec de récupération du client.');
  }
}


  /// 🆕 Créer un client (Admin uniquement)
  static Future<Client> createClient(Client client, int routeId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token manquant.');

    final response = await http.post(
      Uri.parse('$baseUrl/client/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        ...client.toJson(),
        'routeId': routeId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Client.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur ${response.statusCode} : création client échouée.');
    }
  }

  /// ✏️ Modifier un client (Admin uniquement)
  static Future<Client> updateClient(int id, Client client, int routeId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token manquant.');

    final response = await http.put(
      Uri.parse('$baseUrl/client/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        ...client.toJson(),
        'routeId': routeId,
      }),
    );

    if (response.statusCode == 200) {
      return Client.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur ${response.statusCode} : modification client échouée.');
    }
  }

  /// ❌ Supprimer un client (Admin uniquement)
  static Future<void> deleteClient(int id) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token manquant.');

    final response = await http.delete(
      Uri.parse('$baseUrl/client/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur ${response.statusCode} : suppression échouée.');
    }
  }
}
