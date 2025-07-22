import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/categorie_produit.dart';
import '../models/produit.dart';
import '../utils/secure_storage.dart';
import '../config/constants.dart';

class ProduitService {
    static Future<List<CategorieProduit>> getCategories() async {
    final token = await SecureStorage.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => CategorieProduit.fromJson(e)).toList();
    } else {
      throw Exception('Erreur récupération catégories (code: ${response.statusCode})');
    }
  }
static Future<List<Produit>> getAllProduits() async {
  final token = await SecureStorage.getToken();
  final response = await http.get(
    Uri.parse('$baseUrl/produits'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );
  
 
  if (response.statusCode == 200) {
    final List list = jsonDecode(response.body);
    return list.map((json) => Produit.fromJson(json)).toList();
  } else {
    throw Exception('Échec du chargement des produits');
  }
}
  static Future<Produit> createProduit(Produit produit) async {
    final token = await SecureStorage.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/produits/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(produit.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Produit.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la création du produit');
    }
  }

  static Future<Produit> updateProduit(int id, Produit produit) async {
  final token = await SecureStorage.getToken();
  final response = await http.put(
    Uri.parse('$baseUrl/produits/$id'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(produit.toJson()),
  );
  if (response.statusCode == 200) {
    return Produit.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Erreur lors de la mise à jour du produit : ${response.statusCode} ${response.body}');
  }
}


  static Future<void> deleteProduit(int id) async {
    final token = await SecureStorage.getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/produits/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression du produit');
    }
  }
}
