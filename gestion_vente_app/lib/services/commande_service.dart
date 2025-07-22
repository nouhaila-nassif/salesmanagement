import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/commande_dto.dart';
import '../utils/secure_storage.dart';

class CommandeService {
  static Future<List<CommandeDTO>> getCommandes() async {
    final token = await SecureStorage.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/commandes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => CommandeDTO.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors du chargement des commandes');
    }
  }
  // Nouvelle méthode pour mettre à jour une commande (PUT)
  static Future<CommandeDTO> updateCommande(int id, CommandeDTO commande) async {
    final token = await SecureStorage.getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/commandes/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(commande.toJson()), // Assure-toi que CommandeDTO a toJson()
    );

    if (response.statusCode == 200) {
      return CommandeDTO.fromJson(json.decode(response.body));
    } else if (response.statusCode == 403) {
      throw Exception('Accès refusé : vous ne pouvez pas modifier cette commande.');
    } else {
      throw Exception('Erreur lors de la mise à jour de la commande');
    }
  }
  static Future<void> updateCommandeStatut(int id, String nouveauStatut) async {
  final token = await SecureStorage.getToken();

  final response = await http.put(
    Uri.parse('$baseUrl/commandes/$id/changer-statut?nouveauStatut=$nouveauStatut'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Erreur lors de la mise à jour du statut de la commande');
  }
}

static Future<CommandeDTO> getCommandeById(int id) async {
  final token = await SecureStorage.getToken();

  final response = await http.get(
    Uri.parse('$baseUrl/commandes/$id'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return CommandeDTO.fromJson(json.decode(response.body));
  } else if (response.statusCode == 404) {
    throw Exception('Commande #$id introuvable.');
  } else {
    throw Exception('Erreur lors de la récupération de la commande #$id');
  }
}

  // Nouvelle méthode pour annuler une commande (POST /cancel)
static Future<void> cancelCommande(int id) async {
  final token = await SecureStorage.getToken();

  final response = await http.post(
    Uri.parse('$baseUrl/commandes/$id/cancel'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    // Annulation réussie, rien à retourner
    return;
  } else {
    String errorMessage = 'Erreur lors de l\'annulation de la commande.';

    try {
      // Tente de parser la réponse JSON
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body.containsKey('message')) {
        errorMessage = body['message'];
      }
    } catch (_) {
      // Si ce n'est pas un JSON valide, on garde le message générique ou le texte brut
      if (response.body.isNotEmpty) {
        errorMessage = response.body;
      }
    }

    throw Exception(errorMessage);
  }
}
static Future<void> changerStatutCommande(int id, String nouveauStatut) async {
  final token = await SecureStorage.getToken();

  final response = await http.put(
    Uri.parse('$baseUrl/commandes/$id/changer-statut?nouveauStatut=$nouveauStatut'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    // Statut changé avec succès
    return;
  } else {
    String errorMessage = 'Erreur lors du changement de statut.';

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body.containsKey('message')) {
        errorMessage = body['message'];
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
        errorMessage = response.body;
      }
    }

    throw Exception(errorMessage);
  }
}


static Future<void> deleteCommande(int commandeId) async {
  final token = await SecureStorage.getToken();

  final response = await http.delete(
    Uri.parse('$baseUrl/commandes/$commandeId'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Erreur lors de la suppression de la commande');
  }
}


static Future<void> approveCommande(int commandeId) async {
  final token = await SecureStorage.getToken();

  final response = await http.post(
    Uri.parse('$baseUrl/commandes/$commandeId/approve'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    // Approve OK, rien à retourner
    return;
  } else if (response.statusCode == 403) {
    throw Exception('Accès refusé : vous ne pouvez pas approuver cette commande.');
  } else {
    throw Exception('Erreur lors de l\'approbation de la commande');
  }
}


  static Future<CommandeDTO> createCommande(CommandeDTO commande) async {
  final token = await SecureStorage.getToken();

  final response = await http.post(
    Uri.parse('$baseUrl/commandes/create'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode(commande.toJson()),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    return CommandeDTO.fromJson(json.decode(response.body));
  } else {
    // Ici on récupère la réponse texte brute
    final errorMsg = response.body.isNotEmpty ? response.body : 'Erreur inconnue';
    // Affiche en console pour debug
    throw Exception(errorMsg);
  }
}


}

