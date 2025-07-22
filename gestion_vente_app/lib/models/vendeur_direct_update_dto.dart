class VendeurDirectUpdateDTO {
  final String nomUtilisateur;
  final String motDePasse;
  final int superviseurId;

  VendeurDirectUpdateDTO({
    required this.nomUtilisateur,
    required this.motDePasse,
    required this.superviseurId,
  });

  Map<String, dynamic> toJson() => {
    'nomUtilisateur': nomUtilisateur,
    'motDePasse': motDePasse,
    'superviseurId': superviseurId,
  };
}
