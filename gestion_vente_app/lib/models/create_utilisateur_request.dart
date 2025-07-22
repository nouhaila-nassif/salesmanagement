class CreateUtilisateurRequest {
  final String username;
  final String password;
  final String role;
  final int? superviseurId;
  final String? telephone;  // ajout
  final String? email;      // ajout

  CreateUtilisateurRequest({
    required this.username,
    required this.password,
    required this.role,
    this.superviseurId,
    this.telephone,
    this.email,
  });

  Map<String, dynamic> toJson() => {
    "username": username,
    "password": password,
    "role": role,
    if (superviseurId != null) "superviseurId": superviseurId,
    if (telephone != null) "telephone": telephone,
    if (email != null) "email": email,
  };
}
