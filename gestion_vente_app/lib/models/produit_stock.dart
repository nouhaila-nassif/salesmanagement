class ProduitStock {
  final int produitId;
  final String nom;
  final String? marque;
  final double? prixUnitaire;
final String? imageBase64;
  final int quantite;

  ProduitStock({
    required this.produitId,
    required this.nom,
    this.marque,
    this.prixUnitaire,
    this.imageBase64,
    required this.quantite,
  });

  factory ProduitStock.fromJson(Map<String, dynamic> json) {
    return ProduitStock(
      produitId: json['produitId'],
      nom: json['nom'],
      marque: json['marque'],
      prixUnitaire: (json['prixUnitaire'] != null)
          ? (json['prixUnitaire'] as num).toDouble()
          : null,
      imageBase64: json['imageBase64'],

      quantite: json['quantite'],
    );
  }

  Map<String, dynamic> toJson() {
  return {
    'produitId': produitId,
    'nom': nom,
    'marque': marque,
    'prixUnitaire': prixUnitaire,
    'imageBase64': imageBase64, // ✅ corriger ici
    'quantite': quantite,
  };
}

}
