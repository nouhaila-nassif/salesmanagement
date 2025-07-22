import 'package:flutter/material.dart';
import 'package:gestion_vente_app/services/utilisateur_service.dart';
import '../../models/client.dart';
import '../../models/route_model.dart';
import '../../models/utilisateur_response.dart';
import '../../services/client_service.dart';
import '../../services/route_service.dart';
import '../../widgets/navigation_bar.dart';

class RouteListPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final VoidCallback onLogout;
  final void Function(String route, {Map<String, dynamic>? arguments})
      onNavigate;

  const RouteListPage({
    super.key,
    required this.userRole,
    required this.userName,
    required this.onLogout,
    required this.onNavigate,
  });

  @override
  State<RouteListPage> createState() => _RouteListPageState();
}

class _RouteListPageState extends State<RouteListPage> {
  // État de l'application
  late Future<List<RouteModel>> _routesFuture = RouteService.getAllRoutes();
  List<Client> clients = [];
  Client? selectedClient;
  Map<int, List<Client>> _clientsParRoute = {};
  UtilisateurResponse? selectedVendeur;
  List<UtilisateurResponse> vendeurs = [];
RouteModel? _currentRoute;
 
  // Contrôleurs pour le formulaire
  final TextEditingController _nomController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Variables pour gérer l'édition
  bool _isEditing = false;
  int? _editingId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// Charge les données initiales nécessaires pour l'écran
  Future<void> _loadInitialData() async {
    try {
      // 1. D'abord charger les clients
      await _fetchClients();

      // 2. Ensuite charger les vendeurs
      await _fetchVendeurs();

      // 3. Enfin charger les routes avec les clients déjà disponibles
      await _loadRoutes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement: $e')),
      );
    }
  }

  /// Charge la liste des routes depuis l'API
  Future<void> _loadRoutes() async {
    try {
      final routes = await RouteService.getAllRoutes();

      // Injecter les clients dans les routes
      final routesWithClients = routes.map((route) {
        return RouteModel(
          id: route.id,
          nom: route.nom,
          vendeurs: route.vendeurs,
          clients: _clientsParRoute[route.id] ?? [],
        );
      }).toList();

      setState(() {
        _routesFuture = Future.value(routesWithClients);
      });
    } catch (e) {
    }
  }

 
  /// Récupère la liste des clients depuis l'API et les groupe par route
  Future<void> _fetchClients() async {
    try {
      final data = await ClientService.getAllClients();

    

      final Map<int, List<Client>> clientsByRoute = {};
    for (var client in data) {
  for (var route in client.routes) {
    clientsByRoute.putIfAbsent(route.id, () => []).add(client);
  }
}


     

      setState(() {
        clients = data;
        _clientsParRoute = clientsByRoute;
      });
    } catch (e) {
    }
  }

  /// Récupère la liste des vendeurs depuis l'API
  Future<void> _fetchVendeurs() async {
    try {
      final data = await UtilisateurService.getAllVendeurs();
      setState(() {
        vendeurs = data;
      });
    } catch (e) {
      print('Erreur lors du chargement des vendeurs : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des vendeurs: $e')),
      );
    }
  }

  /// Affiche le formulaire d'ajout/modification d'une route
void _showFormDialog({RouteModel? route}) {
    _currentRoute = route;  // Sauvegarde la route actuelle

  if (route != null) {
    _isEditing = true;
    _editingId = route.id;
    _nomController.text = route.nom;

    // Préremplir vendeur si présent
  selectedVendeur = route.vendeurs.isNotEmpty
    ? vendeurs.firstWhere(
        (v) => v.id == route.vendeurs.first.id,
      )
    : null;

    // Préremplir client si présent
    selectedClient = route.clients.isNotEmpty
    ? clients.firstWhere(
        (c) => c.id == route.clients.first.id,
      )
    : null;

  } else {
    _isEditing = false;
    _editingId = null;
    _nomController.clear();
    selectedVendeur = null;
    selectedClient = null;
  }

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(_isEditing ? 'Modifier la route' : 'Ajouter une route'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Champ nom de la route
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Nom requis' : null,
              ),
              const SizedBox(height: 16),

              // Sélecteur de vendeur
              DropdownButtonFormField<UtilisateurResponse>(
                value: vendeurs.contains(selectedVendeur) ? selectedVendeur : null,
                items: [
                  const DropdownMenuItem<UtilisateurResponse>(
                    value: null,
                    child: Text('Aucun vendeur'),
                  ),
                  ...vendeurs.map((v) => DropdownMenuItem<UtilisateurResponse>(
                        value: v,
                        child: Text(v.nomUtilisateur),
                      )),
                ],
                onChanged: (value) => setState(() => selectedVendeur = value),
                decoration: const InputDecoration(labelText: 'Sélectionner un vendeur'),
              ),
              const SizedBox(height: 16),

             
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: Text(_isEditing ? 'Modifier' : 'Ajouter'),
        ),
      ],
    ),
  );
}

  /// Soumet le formulaire d'ajout/modification
  Future<void> _submitForm() async {
    // Pour l'édition, on saute la validation des champs vides
    if (!_isEditing && !_formKey.currentState!.validate()) return;

    try {
      int routeId = _editingId ?? -1;

      if (_isEditing && _editingId != null) {
        // Modification partielle - seulement ce qui a été changé
        if (_nomController.text.isNotEmpty) {
          await RouteService.updateRoute(
              _editingId!, RouteDTO(nom: _nomController.text));
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nom de route mis à jour')));
        }
        routeId = _editingId!;
      } else {
        // Création - validation complète
        final createdRoute = await RouteService.createRoute(
          RouteDTO(nom: _nomController.text),
        );
        routeId = createdRoute.id;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nouvelle route créée')));
      }

      // Assignations optionnelles
      if (selectedVendeur != null) {
        await RouteService.assignerVendeurARoute(routeId, selectedVendeur!.id);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vendeur assigné/mis à jour')));
      }

      if (selectedClient != null) {
        await RouteService.assignerClientARoute(routeId, selectedClient!.id);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client assigné/mis à jour')));
      }

      Navigator.pop(context);
      _loadRoutes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }
  /// Supprime une route après confirmation
  Future<void> _deleteRoute(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous supprimer cette route ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await RouteService.deleteRoute(id);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Route supprimée')));
        _loadRoutes();
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des routes'),
           backgroundColor: Theme.of(context).primaryColor,
               foregroundColor: Colors.white,
                centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoutes,
            tooltip: 'Actualiser',
          ),
        ],),
    drawer: MainNavigationBar(
  userRole: widget.userRole,
  userName: widget.userName,
  onLogout: widget.onLogout,
  onNavigate: widget.onNavigate,
  currentRoute: ModalRoute.of(context)?.settings.name ?? "/home", // ✅ Détecte la page actuelle
  newOrdersCount: 5, // ✅ Exemple : badge avec 5 nouvelles commandes
),

      body: FutureBuilder<List<RouteModel>>(
        future: _routesFuture,
        builder: (context, snapshot) {
          // Gestion des états de chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final routes = snapshot.data ?? [];
          if (routes.isEmpty) {
            return const Center(child: Text('Aucune route trouvée'));
          }

          return RefreshIndicator(
            onRefresh: () async => _loadRoutes(),
            child: ListView.builder(
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(
                        route.nom,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Vendeurs
                          if (route.vendeurs.isNotEmpty) ...[
                            Text(
                              'Vendeurs:',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 2),
                            Wrap(
                              spacing: 4,
                              children: route.vendeurs
                                  .map((v) => Chip(
                                        label: Text(v.nomUtilisateur),
                                        visualDensity: VisualDensity.compact,
                                      ))
                                  .toList(),
                            ),
                            SizedBox(height: 8),
                          ],

                          // Section Clients
                          if (route.clients.isNotEmpty) ...[
                            Text(
                              'Clients:',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 2),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: route.clients
                                  .map((c) => Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.person_outline,
                                                size: 16),
                                            SizedBox(width: 4),
                                            Text(c.nom),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ] else ...[
                            SizedBox(height: 4),
                            Text(
                              'Aucun client assigné',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showFormDialog(route: route);
                          } else if (value == 'delete') {
                            _deleteRoute(route.id);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Modifier'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Supprimer',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      onTap: () {
                        // Option: Ajouter une action quand on clique sur la route
                      },
                    ));
              },
            ),
          );
        },
      ),
      // Bouton pour ajouter une nouvelle route
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
