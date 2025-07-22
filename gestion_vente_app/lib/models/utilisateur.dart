class Utilisateur {
  final String token;
  final String role;
final String nom;
  Utilisateur({required this.token, required this.role, this.nom = '' });

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      token: json['token'],
      role: json['role'],
    );
  }
}
