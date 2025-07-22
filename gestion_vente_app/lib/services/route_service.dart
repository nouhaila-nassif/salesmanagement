import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/route_model.dart';
import '../utils/secure_storage.dart';

class RouteService {
  /// Récupérer toutes les routes
static Future<List<RouteModel>> getAllRoutes() async {
  final token = await SecureStorage.getToken();
  if (token == null) {
    throw Exception('Token manquant. Veuillez vous reconnecter.');
  }

  final response = await http.get(
    Uri.parse('$baseUrl/routes'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  try {
    if (response.statusCode == 200) {
      // Debug : afficher le JSON brut

      // Vérifie si la réponse est un JSON valide
      final decoded = json.decode(response.body);
      if (decoded is List) {
        return decoded.map((jsonItem) => RouteModel.fromJson(jsonItem)).toList();
      } else {
        throw Exception('Format inattendu : la réponse n’est pas une liste.');
      }
    } else {
      throw Exception('Erreur ${response.statusCode} : impossible de charger les routes.');
    }
  } catch (e) {
    throw Exception('Données invalides reçues du serveur.');
  }
}

static Future<void> supprimerTousLesVendeursDeRoute(int routeId) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/routes/$routeId/vendeurs'),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode != 204) {
    throw Exception("Erreur lors de la suppression des vendeurs de la route");
  }
}

static Future<void> supprimerTousLesClientsDeRoute(int routeId) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/routes/$routeId/clients'),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode != 204) {
    throw Exception("Erreur lors de la suppression des clients de la route");
  }
}

  /// Créer une route
  static Future<RouteModel> createRoute(RouteDTO routeDTO) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token manquant.');

    final response = await http.post(
      Uri.parse('$baseUrl/routes/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(routeDTO.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return RouteModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur ${response.statusCode} : création route échouée.');
    }
  }

  /// Mettre à jour une route
  static Future<RouteModel> updateRoute(int id, RouteDTO routeDTO) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token manquant.');

    final response = await http.put(
      Uri.parse('$baseUrl/routes/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(routeDTO.toJson()),
    );

    if (response.statusCode == 200) {
      return RouteModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur ${response.statusCode} : modification route échouée.');
    }
  }
  //Assigner un utilisateur à une route
static Future<void> assignerUtilisateurARoute(int routeId, int userId) async {
  final token = await SecureStorage.getToken();
  if (token == null) throw Exception("Token manquant.");

  final response = await http.post(
    Uri.parse('$baseUrl/routes/$routeId/assignUser/$userId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw Exception("Erreur assignation utilisateur : ${response.body}");
  }
}
//Assigner un vendeur à une route
static Future<void> assignerVendeurARoute(int routeId, int vendeurId) async {
  final token = await SecureStorage.getToken();
  if (token == null) throw Exception("Token manquant.");

  final response = await http.post(
    Uri.parse('$baseUrl/routes/$routeId/assignVendeur/$vendeurId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw Exception("Erreur assignation vendeur : ${response.body}");
  }
}
// Assigner un client à une route
static Future<void> assignerClientARoute(int routeId, int clientId) async {
  final token = await SecureStorage.getToken();
  if (token == null) throw Exception("Token manquant.");

  final response = await http.post(
    Uri.parse('$baseUrl/routes/$routeId/assignClient/$clientId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw Exception("Erreur assignation client : ${response.body}");
  }
}

// Désassigner un client d’une route
static Future<void> unassignerClient(int routeId, int clientId) async {
  final token = await SecureStorage.getToken();
  if (token == null) throw Exception("Token manquant.");

  final response = await http.delete(
    Uri.parse('$baseUrl/routes/$routeId/clients/$clientId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode != 200 && response.statusCode != 204) {
    throw Exception("Erreur désassignation client : ${response.body}");
  }
}

  /// Supprimer une route
  static Future<void> deleteRoute(int id) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token manquant.');

    final response = await http.delete(
      Uri.parse('$baseUrl/routes/$id'),
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
