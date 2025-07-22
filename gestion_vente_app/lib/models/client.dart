import 'route_model.dart';

class Client {
  final int id;
  final String nom;
  final String type;
  final String telephone;
  final String email;
  final String adresse;
  final String derniereVisite;
  final List<RouteModel> routes;  // Liste de routes

  Client({
    required this.id,
    required this.nom,
    required this.type,
    required this.telephone,
    required this.email,
    required this.adresse,
    required this.derniereVisite,
    required this.routes,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      nom: json['nom'] ?? '',
      type: json['type'] ?? '',
      telephone: json['telephone'] ?? '',
      email: json['email'] ?? '',
      adresse: json['adresse'] ?? '',
      derniereVisite: json['derniereVisite'] ?? '',
      routes: (json['routes'] as List<dynamic>?)
              ?.map((r) => RouteModel.fromJson(r))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'type': type,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
      'derniereVisite': derniereVisite,
      'routes': routes.map((r) => r.toJson()).toList(),
    };
  }

  // Getter pratique pour afficher le premier nom de route (ou un message)
  String get premiereRouteNom => routes.isNotEmpty ? routes.first.nom : 'Aucune route';
}
