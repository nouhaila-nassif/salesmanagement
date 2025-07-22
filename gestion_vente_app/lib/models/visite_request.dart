class Visite {
  final DateTime datePlanifiee;
  final String nomClient;
  final String nomVendeur;
  final String typeClient; // Peut être enum plus tard si besoin
  final String adresse;
  final String numeroTelephone;
  final String email;

  Visite({
    required this.datePlanifiee,
    required this.nomClient,
    required this.nomVendeur,
    required this.typeClient,
    required this.adresse,
    required this.numeroTelephone,
    required this.email,
  });

  factory Visite.fromJson(Map<String, dynamic> json) {
    return Visite(
      datePlanifiee: DateTime.parse(json['datePlanifiee']),
      nomClient: json['nomClient'] ?? '',
      nomVendeur: json['nomVendeur'] ?? '',
      typeClient: json['typeClient'] ?? '',
      adresse: json['adresse'] ?? '',
      numeroTelephone: json['numeroTelephone'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'datePlanifiee': datePlanifiee.toIso8601String(),
      'nomClient': nomClient,
      'nomVendeur': nomVendeur,
      'typeClient': typeClient,
      'adresse': adresse,
      'numeroTelephone': numeroTelephone,
      'email': email,
    };
  }
}
