import 'Categorie.dart';
import 'produit.dart';

class Promotion {
  final int? id;
  final String nom;
  final String type;
  final double tauxReduction;
  final DateTime dateDebut;
  final DateTime dateFin;
  final Categorie? categorie;
Produit? produitCondition;
Produit? produitOffert;

  final double? discountValue;
  final int? seuilQuantite;

  // Noms des produits concernés par la promo (condition et offert)
  final String? produitConditionNom;
  final int? quantiteCondition;
  final String? produitOffertNom;
  final int? quantiteOfferte;

  Promotion({
    this.id,
    required this.nom,
    required this.type,
    required this.tauxReduction,
    required this.dateDebut,
    required this.dateFin,
    this.categorie,
    this.discountValue,
    this.seuilQuantite,
    this.produitConditionNom,
    this.quantiteCondition,
    this.produitOffertNom,
    this.quantiteOfferte,
    this.produitCondition,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'],
      nom: json['nom'] ?? '',
      type: json['type'] ?? 'TPR',
      tauxReduction: json['tauxReduction'] != null
          ? (json['tauxReduction'] as num).toDouble()
          : 0.0,
      dateDebut: json['dateDebut'] != null
          ? DateTime.parse(json['dateDebut'])
          : DateTime.now(),
      dateFin: json['dateFin'] != null
          ? DateTime.parse(json['dateFin'])
          : DateTime.now().add(const Duration(days: 30)),
      categorie: json['categorie'] is Map
          ? Categorie.fromJson(json['categorie'] as Map<String, dynamic>)
          : (json['categorie'] != null
              ? Categorie(id: json['categorie'], nom: 'Catégorie ${json['categorie']}')
              : null),
      discountValue: json['discountValue'] != null
          ? (json['discountValue'] as num).toDouble()
          : null,
      seuilQuantite: json['seuilQuantite'] is int
          ? json['seuilQuantite']
          : (json['seuilQuantite'] != null
              ? int.tryParse(json['seuilQuantite'].toString())
              : null),
      produitConditionNom: json['produitConditionNom'],
      quantiteCondition: json['quantiteCondition'] is int
          ? json['quantiteCondition']
          : (json['quantiteCondition'] != null
              ? int.tryParse(json['quantiteCondition'].toString())
              : null),
           produitCondition: json['produitCondition'] != null
          ? Produit.fromJson(json['produitCondition'])
          : null,     
      produitOffertNom: json['produitOffertNom'],
      quantiteOfferte: json['quantiteOfferte'] is int
          ? json['quantiteOfferte']
          : (json['quantiteOfferte'] != null
              ? int.tryParse(json['quantiteOfferte'].toString())
              : null),
              
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'type': type,
      'tauxReduction': tauxReduction,
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin.toIso8601String(),
      'categorie': categorie?.toJson(),
      'discountValue': discountValue,
      'seuilQuantite': seuilQuantite,
      'produitConditionNom': produitConditionNom,
      'quantiteCondition': quantiteCondition,
      'produitOffertNom': produitOffertNom,
      'quantiteOfferte': quantiteOfferte,
      
    };
  }
}
