class LoginRequest {
  final String nomUtilisateur;
  final String motDePasse;

  LoginRequest({required this.nomUtilisateur, required this.motDePasse});

  Map<String, dynamic> toJson() => {
        'nomUtilisateur': nomUtilisateur,
        'motDePasse': motDePasse,
      };
}
