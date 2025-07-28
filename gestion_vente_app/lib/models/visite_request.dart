class Visite {
  final int id; // utile pour modifier le statut
  final DateTime datePlanifiee;
  final DateTime? dateReelle;  // nullable car parfois null
  final String nomClient;
  final String nomVendeur;
  final String typeClient;
  final String adresse;
  final String numeroTelephone;
  final String email;
  final String statut; // obligatoire désormais

  Visite({
    required this.id,
    required this.datePlanifiee,
    this.dateReelle,
    required this.nomClient,
    required this.nomVendeur,
    required this.typeClient,
    required this.adresse,
    required this.numeroTelephone,
    required this.email,
    required this.statut,
  });

  factory Visite.fromJson(Map<String, dynamic> json) {
    return Visite(
      id: json['id'] ?? 0, // 0 par défaut ou lever une erreur si id manquant
      datePlanifiee: DateTime.parse(json['datePlanifiee']),
      dateReelle: json['dateReelle'] != null ? DateTime.parse(json['dateReelle']) : null,
      nomClient: json['nomClient'] ?? '',
      nomVendeur: json['nomVendeur'] ?? '',
      typeClient: json['typeClient'] ?? '',
      adresse: json['adresse'] ?? '',
      numeroTelephone: json['numeroTelephone'] ?? '',
      email: json['email'] ?? '',
      statut: json['statut'] ?? 'PLANIFIEE', // valeur par défaut
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'datePlanifiee': datePlanifiee.toIso8601String(),
      'dateReelle': dateReelle?.toIso8601String(),
      'nomClient': nomClient,
      'nomVendeur': nomVendeur,
      'typeClient': typeClient,
      'adresse': adresse,
      'numeroTelephone': numeroTelephone,
      'email': email,
      'statut': statut,
    };
  }
}
