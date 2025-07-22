class UpdateUtilisateurRequest {
  final String nomUtilisateur;
  final String? motDePasse;
  final String? telephone;
  final String? email;
  final String? userType;        // Ajouté pour modifier le rôle si nécessaire
  final int? superviseurId;      // Ajouté pour VENDEURDIRECT ou PREVENDEUR

  UpdateUtilisateurRequest({
    required this.nomUtilisateur,
    this.motDePasse,
    this.telephone,
    this.email,
    this.userType,
    this.superviseurId,
  });

  Map<String, dynamic> toJson() {
    return {
      'nomUtilisateur': nomUtilisateur,
      'motDePasse': motDePasse,
      'telephone': telephone,
      'email': email,
      'userType': userType,
      'superviseurId': superviseurId,
    };
  }
}
