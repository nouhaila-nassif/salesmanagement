import 'promotion.dart'; // N'oublie pas d'importer la classe Promotion

class Produit {
  final int? id;
  final String nom;
  final String marque;
  final double prixUnitaire;
  final String? imageBase64;
  final int? categorieId;
  final String? categorieNom;
  final String description;
  final List<Promotion>? promotions; // ✅ liste de promotions

  Produit({
    this.id,
    required this.nom,
    required this.marque,
    required this.prixUnitaire,
    this.imageBase64,
    required this.categorieId,
    this.categorieNom,
    required this.description,
    this.promotions,
  });

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      id: json['id'],
      nom: json['nom'],
      marque: json['marque'] ?? '',
      prixUnitaire: (json['prixUnitaire'] as num).toDouble(),
      imageBase64: json['imageBase64'],
      categorieId: json['categorieId'],
      categorieNom: json['categorieNom'],
      description: json['description'] ?? '',
      promotions: json['promotions'] != null
          ? List<Promotion>.from(
              (json['promotions'] as List).map((e) => Promotion.fromJson(e)),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'marque': marque,
      'prixUnitaire': prixUnitaire,
      'imageBase64': imageBase64,
      'categorieId': categorieId,
      'categorieNom': categorieNom,
      'description': description,
      'promotions': promotions?.map((p) => p.toJson()).toList(), // ✅ list
    };
  }
}
