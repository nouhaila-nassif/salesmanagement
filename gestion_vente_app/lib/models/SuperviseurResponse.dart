class SuperviseurResponse {
  final int id;
  final String nomUtilisateur;

  SuperviseurResponse({
    required this.id,
    required this.nomUtilisateur,
  });

  factory SuperviseurResponse.fromJson(Map<String, dynamic> json) {
    return SuperviseurResponse(
      id: json['id'],
      nomUtilisateur: json['nomUtilisateur'] ?? 'Inconnu',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomUtilisateur': nomUtilisateur,
    };
  }
}
