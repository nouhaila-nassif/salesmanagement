import 'produit.dart';

class LigneCommande {
  final int? id;
  final int produitId;
  final int quantite;
  final Produit produit;
  final bool produitOffert;

  LigneCommande({
    required this.id,
    required this.produitId,
    required this.quantite,
    required this.produit,
    required this.produitOffert,
  });

  factory LigneCommande.fromJson(Map<String, dynamic> json) {
    return LigneCommande(
      id: json['id'] ?? 0,
      produitId: json['produitId'] ?? 0,
      quantite: json['quantite'] ?? 0,
      produit: Produit.fromJson(json['produit'] ?? {}),
      produitOffert: json['produitOffert'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produitId': produitId,
      'quantite': quantite,
      'produit': produit.toJson(),
      'produitOffert': produitOffert,
    };
  }

  // ✅ Méthode copyWith
  LigneCommande copyWith({
    int? id,
    int? produitId,
    int? quantite,
    Produit? produit,
    bool? produitOffert,
  }) {
    return LigneCommande(
      id: id ?? this.id,
      produitId: produitId ?? this.produitId,
      quantite: quantite ?? this.quantite,
      produit: produit ?? this.produit,
      produitOffert: produitOffert ?? this.produitOffert,
    );
  }
}
