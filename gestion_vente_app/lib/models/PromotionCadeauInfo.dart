
class PromotionCadeauInfo {
  final int promotionId;
  final String produitOffertNom;
  final int quantite;
  final String? produitConditionNom;
  final int? quantiteCondition;

  PromotionCadeauInfo({
    required this.promotionId,
    required this.produitOffertNom,
    required this.quantite,
    this.produitConditionNom,
    this.quantiteCondition,
  });

  factory PromotionCadeauInfo.fromJson(Map<String, dynamic> json) {
    return PromotionCadeauInfo(
      promotionId: json['promotionId'] as int,
      produitOffertNom: json['produitOffertNom'] as String,
      quantite: json['quantite'] as int,
      produitConditionNom: json['produitConditionNom'] as String?,
      quantiteCondition: json['quantiteCondition'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'promotionId': promotionId,
      'produitOffertNom': produitOffertNom,
      'quantite': quantite,
      'produitConditionNom': produitConditionNom,
      'quantiteCondition': quantiteCondition,
    };
  }
}