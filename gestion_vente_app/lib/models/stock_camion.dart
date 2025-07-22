import 'produit_stock.dart';

class StockCamion {
  final int id;
  final String chauffeur;
  final List<ProduitStock> niveauxStock;

  StockCamion({
    required this.id,
    required this.chauffeur,
    required this.niveauxStock,
  });

factory StockCamion.fromJson(Map<String, dynamic> json) {
  // Gestion du chauffeur
  String chauffeurNom = "Inconnu";
  if (json['chauffeur'] is Map<String, dynamic>) {
    chauffeurNom = json['chauffeur']['nomUtilisateur'] ?? "Inconnu";
  } else if (json['chauffeur'] is String) {
    chauffeurNom = json['chauffeur'];
  }

  // Correction ici : niveauxStock est une List
  final niveauxStockJson = json['niveauxStock'] as List<dynamic>? ?? [];
  final List<ProduitStock> produits = niveauxStockJson
      .map((e) => ProduitStock.fromJson(e as Map<String, dynamic>))
      .toList();

  return StockCamion(
    id: json['id'] ?? 0,
    chauffeur: chauffeurNom,
    niveauxStock: produits,
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chauffeur': chauffeur,
      'niveauxStock': niveauxStock.map((p) => p.toJson()).toList(),
    };
  }
}
