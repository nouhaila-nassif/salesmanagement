import 'PromotionCadeauInfo.dart';
import 'ligne_commande_dto.dart';
import 'promotion.dart';

class CommandeDTO {
  final int id;
  final String dateCreation;
  late final String statut;
  final int? clientId;               // autoriser null
  final int? vendeurId;              // autoriser null
  final String clientNom;
  final String vendeurNom;
  final List<LigneCommande> lignes;
  final String dateLivraison;
  final double montantReduction;
  final double montantTotal;
  final double montantTotalAvantRemise;
  final List<int> promotionIds;
  final List<PromotionCadeauInfo> promotionsCadeaux;
  final List<Promotion> promotions;
final List<Promotion> promotionsAppliquees;

  CommandeDTO({
    required this.id,
    required this.dateCreation,
    required this.statut,
    this.clientId,
    this.vendeurId,
    required this.clientNom,
    required this.vendeurNom,
    required this.lignes,
    required this.dateLivraison,
    required this.montantReduction,
    required this.montantTotal,
    required this.montantTotalAvantRemise,
    required this.promotionIds,
    required this.promotionsCadeaux,
        this.promotions = const [],
    this.promotionsAppliquees = const [],

  });

  factory CommandeDTO.fromJson(Map<String, dynamic> json) {
    return CommandeDTO(
      id: json['id'] ?? 0,
      dateCreation: json['dateCreation'] ?? '',
      statut: json['statut'] ?? '',
      clientId: json['clientId'] as int?,
      vendeurId: json['vendeurId'] as int?,
      clientNom: json['clientNom'] ?? '',
      vendeurNom: json['vendeurNom'] ?? '',
      lignes: (json['lignes'] as List<dynamic>? ?? [])
          .map((ligne) => LigneCommande.fromJson(ligne))
          .toList(),
      dateLivraison: json['dateLivraison'] ?? '',
      montantReduction: (json['montantReduction'] ?? 0).toDouble(),
      montantTotal: (json['montantTotal'] ?? 0).toDouble(),
      montantTotalAvantRemise:
          (json['montantTotalAvantRemise'] ?? 0).toDouble(),
      promotionIds: (json['promotionIds'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
      promotionsCadeaux: (json['promotionsCadeaux'] as List<dynamic>?)
          ?.map((e) => PromotionCadeauInfo.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      promotions: (json['promotions'] as List<dynamic>?)
              ?.map((e) => Promotion.fromJson(e))
              .toList() ??
          [],
          promotionsAppliquees: (json['promotionsAppliquees'] as List<dynamic>?)
    ?.map((e) => Promotion.fromJson(e))
    .toList() ?? [],

    );
  }

 Map<String, dynamic> toJson() {
  return {
    'id': id,
    'dateCreation': dateCreation, // si possible, garder aussi juste la date ou timestamp complet selon backend
    'statut': statut,
    'clientId': clientId,
    'vendeurId': vendeurId,
    'clientNom': clientNom,
    'vendeurNom': vendeurNom,
    'lignes': lignes.map((ligne) => ligne.toJson()).toList(),
    'dateLivraison': dateLivraison,  // doit être en "yyyy-MM-dd"
    'montantReduction': montantReduction,
    'montantTotal': montantTotal,
    'montantTotalAvantRemise': montantTotalAvantRemise,
    'promotionIds': promotionIds,
   'promotions': promotions.map((p) => p.toJson()).toList(),
    'promotionsCadeaux': promotionsCadeaux.map((p) => p.toJson()).toList(),
    'promotionsAppliquees': promotionsAppliquees.map((p) => p.toJson()).toList(),
    

  };
}

}
