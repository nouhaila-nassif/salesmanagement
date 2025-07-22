import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/stock_camion.dart';
import '../utils/secure_storage.dart';

class StockService {
  Future<Map<String, String>> _headers() async {
    final token = await SecureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

Future<StockCamion?> getMonStock() async {
  final response = await http.get(
    Uri.parse('$baseUrl/stock-camion/moi'),
    headers: await _headers(),
  );

  if (response.statusCode == 200) {
    try {
      final jsonMap = jsonDecode(response.body);
      return StockCamion.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  } else if (response.statusCode == 404) {
    return null;
  } else {
    throw Exception('Erreur API : ${response.statusCode}');
  }
}

  /// Créer un stock pour le vendeur connecté (POST /creer)
Future<StockCamion?> creerMonStock() async {
  final response = await http.post(
    Uri.parse('$baseUrl/stock-camion/creer'),
    headers: await _headers(),
  );


  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body);
      return StockCamion.fromJson(data);
    } catch (e) {
      return null;
    }
  } else {
    return null;
  }
}



/// Supprimer un produit d'un stock (DELETE /{stockId}/produit/{produitId})
Future<bool> supprimerProduitDuStock({
  required int stockId,
  required int produitId,
}) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/stock-camion/$stockId/produit/$produitId'),
    headers: await _headers(),
  );

  return response.statusCode == 200;
}

  /// Charger du stock (POST /charger)
  Future<bool> chargerStock({
    required int stockId,
    required int produitId,
    required int quantite,
  }) async {
    final body = {
      'stockId': stockId,
      'produitId': produitId,
      'quantite': quantite,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/stock-camion/charger'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  /// Déduire du stock (POST /deduire?produitId=..&quantite=..)
  Future<bool> deduireStock({
    required int produitId,
    required int quantite,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/stock-camion/deduire?produitId=$produitId&quantite=$quantite'),
      headers: await _headers(),
    );

    return response.statusCode == 200;
  }

  /// Voir tous les stocks (GET /tous) [Admin, Superviseur, Responsable Unité]
Future<List<StockCamion>> getTousLesStocks() async {
  final response = await http.get(
    Uri.parse('$baseUrl/stock-camion/tous'),
    headers: await _headers(),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => StockCamion.fromJson(json)).toList();
  } else {
    throw Exception("Erreur ${response.statusCode} : ${response.reasonPhrase}");
  }
}

  /// Supprimer un stock (DELETE /supprimer/{stockId})
  Future<bool> supprimerStock(int stockId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/stock-camion/supprimer/$stockId'),
      headers: await _headers(),
    );

    return response.statusCode == 200;
  }

  /// Modifier un stock manuellement (PUT /modifier)
  Future<bool> modifierStockManuellement({
    required int stockId,
    required int produitId,
    required int nouvelleQuantite,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/stock-camion/modifier'
          '?stockId=$stockId&produitId=$produitId&nouvelleQuantite=$nouvelleQuantite'),
      headers: await _headers(),
    );

    return response.statusCode == 200;
  }
}
