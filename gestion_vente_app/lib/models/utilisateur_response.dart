class UtilisateurResponse {
  final int id;
  final String nomUtilisateur;
  final String role;
  final String? telephone;
  final String? email;
  final int? superviseurId;
  final String? superviseurNom;

  UtilisateurResponse({
    required this.id,
    required this.nomUtilisateur,
    required this.role,
    this.telephone,
    this.email,
    this.superviseurId,
    this.superviseurNom,
  });

  factory UtilisateurResponse.fromJson(Map<String, dynamic> json) {
    return UtilisateurResponse(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nomUtilisateur: json['nomUtilisateur']?.toString() ?? 'Inconnu',
      role: json['role']?.toString() ?? 'Inconnu',
      telephone: json['telephone']?.toString(),
      email: json['email']?.toString(),
      superviseurId: json['superviseurId'] is int ? json['superviseurId'] : (json['superviseurId'] != null ? int.parse(json['superviseurId'].toString()) : null),
      superviseurNom: json['superviseurNom']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomUtilisateur': nomUtilisateur,
      'role': role,
      'telephone': telephone,
      'email': email,
      'superviseurId': superviseurId,
      'superviseurNom': superviseurNom,
    };
  }
}
