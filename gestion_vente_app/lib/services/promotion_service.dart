import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/promotion.dart';
import '../utils/secure_storage.dart';

class PromotionService {

static Future<List<Promotion>> getAllPromotions() async {
    final token = await SecureStorage.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/promotions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Promotion.fromJson(e)).toList();
    } else {
      throw Exception('Erreur chargement promotions');
    }
  }

static Future<Promotion> updatePromotion(int id, Promotion promo) async {
  final response = await http.put(
    Uri.parse('$baseUrl/promotions/$id'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${await SecureStorage.getToken()}',
    },
    body: jsonEncode(promo.toJson()),
  );

  if (response.statusCode == 200) {
    // Mise à jour réussie, on récupère la promotion mise à jour
    final jsonResponse = jsonDecode(response.body);
    return Promotion.fromJson(jsonResponse);
  } else if (response.statusCode == 404) {
    // Promotion ou produit introuvable côté backend
    throw Exception("Promotion non trouvée (404) : ${response.body}");
  } else {
    // Autres erreurs (500, 400, etc.)
    throw Exception("Erreur de mise à jour (${response.statusCode}) : ${response.body}");
  }
}

 /// Appliquer une promotion sur une catégorie
  static Future<void> appliquerPromotionSurCategorie(int promotionId, int categorieId) async {
    final token = await SecureStorage.getToken();
    final uri = Uri.parse('$baseUrl/promotions/apply?promotionId=$promotionId&categorieId=$categorieId');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de l\'application de la promotion : ${response.body}');
    }
  }

  /// Récupérer les promotions d'une catégorie
  static Future<List<Promotion>> getPromotionsParCategorie(int categorieId) async {
    final token = await SecureStorage.getToken();
    final uri = Uri.parse('$baseUrl/promotions/categorie/$categorieId');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Promotion.fromJson(e)).toList();
    } else {
      throw Exception('Erreur lors du chargement des promotions par catégorie');
    }
  }
 
 
 static Future<Promotion> createPromotion(Promotion promo) async {
  final token = await SecureStorage.getToken();

  final response = await http.post(
    Uri.parse('$baseUrl/promotions'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(promo.toJson()),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    final responseBody = jsonDecode(response.body);
    return Promotion.fromJson(responseBody);
  } else {
    String message = 'Erreur création promotion';

    try {
      final errorBody = jsonDecode(response.body);
      if (errorBody is Map<String, dynamic> && errorBody.containsKey('message')) {
        message = errorBody['message'];
      }
    } catch (e) {
      // Ignorer l'erreur de parsing JSON d'erreur
    }

    throw Exception(message);
  }
}

  static Future<void> deletePromotion(int id) async {
    final token = await SecureStorage.getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/promotions/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur suppression promotion');
    }
  }
}
