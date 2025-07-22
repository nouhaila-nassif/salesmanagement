class CategorieProduit {
  final int id;
  final String nom;
  final String description;

  CategorieProduit({
    required this.id,
    required this.nom,
    required this.description,
  });

  factory CategorieProduit.fromJson(Map<String, dynamic> json) {
    return CategorieProduit(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
    );
  }
}
