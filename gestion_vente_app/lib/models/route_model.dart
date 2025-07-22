import 'client.dart';
import 'utilisateur_response.dart';

class RouteDTO {
  final String nom;

  RouteDTO({required this.nom});

  Map<String, dynamic> toJson() => {
        'nom': nom,
      };
}

class RouteModel {
  final int id;
  final String nom;
  final List<UtilisateurResponse> vendeurs;
  final List<Client> clients;

  RouteModel({
    required this.id,
    required this.nom,
    required this.vendeurs,
    this.clients = const [],
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
  return RouteModel(
    id: json['id'],
    nom: json['nom'],
    vendeurs: (json['vendeurs'] as List<dynamic>?)
            ?.map((v) => UtilisateurResponse.fromJson(v))
            .toList() ??
        [],
    clients: (json['clients'] as List<dynamic>?)
            ?.map((c) => Client.fromJson(c))
            .toList() ??
        [],
  );
}


  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'vendeurs': vendeurs.map((v) => v.toJson()).toList(),
        'clients': clients.map((c) => c.toJson()).toList(),
      };
}
