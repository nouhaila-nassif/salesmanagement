class Categorie {
  final int id;
  final String nom;
  final String? description;

  Categorie({required this.id, required this.nom, this.description});

  factory Categorie.fromJson(Map<String, dynamic> json) => Categorie(
    id: json['id'],
    nom: json['nom'],
    description: json['description'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'description': description,
  };
}
