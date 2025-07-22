import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../models/route_model.dart';
import '../../services/client_service.dart';
import '../../services/route_service.dart';
import '../../widgets/navigation_bar.dart';

class ListeClientsPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final VoidCallback onLogout;
  final void Function(String route, {Map<String, dynamic>? arguments})
      onNavigate;

  const ListeClientsPage({
    Key? key,
    required this.userRole,
    required this.userName,
    required this.onLogout,
    required this.onNavigate,
  }) : super(key: key);

  @override
  State<ListeClientsPage> createState() => _ListeClientsPageState();
}

class _ListeClientsPageState extends State<ListeClientsPage> {
  late Future<List<Client>> _clientsFuture;
  List<dynamic> routes = []; // Ajout de la variable routes

  @override
  void initState() {
    super.initState();
    _loadClients();
  }


  List<Client> allClients = []; // Tous les clients récupérés
  List<Client> filteredClients = []; // Clients filtrés par recherche
  TextEditingController _searchController = TextEditingController();
  void _filterClients(String query) {
    setState(() {
      filteredClients = allClients
          .where((c) => c.nom.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _loadClients() {
    setState(() {
      _clientsFuture = ClientService.getClientsForCurrentUser().then((clients) {
        allClients = clients;
        filteredClients = clients; // Initialement tout
        return clients;
      });
    });
  }

  Future<void> _deleteClient(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce client ?'),
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

    if (confirmed == true) {
      try {
        await ClientService.deleteClient(id);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Client supprimé.')));
        _loadClients();
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur suppression : $e')));
      }
    }
  }

  void _showClientForm({Client? client}) {
    final _formKey = GlobalKey<FormState>();
    String nom = client?.nom ?? '';
    String adresse = client?.adresse ?? '';
    String telephone = client?.telephone ?? '';
    String email = client?.email ?? '';
    String type = client?.type ?? '';
    int? selectedRouteId;

    List<RouteModel> routes = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<List<RouteModel>>(
        future: RouteService.getAllRoutes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Erreur chargement routes : ${snapshot.error}'),
            );
          }

          routes = snapshot.data!;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) => SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          client == null
                              ? 'Créer un client'
                              : 'Modifier un client',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      // Champs texte
                      TextFormField(
                        initialValue: nom,
                        decoration: const InputDecoration(labelText: 'Nom'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Obligatoire' : null,
                        onChanged: (v) => nom = v,
                      ),
                      TextFormField(
                        initialValue: adresse,
                        decoration: const InputDecoration(labelText: 'Adresse'),
                        onChanged: (v) => adresse = v,
                      ),
                      TextFormField(
                        initialValue: telephone,
                        decoration:
                            const InputDecoration(labelText: 'Téléphone'),
                        onChanged: (v) => telephone = v,
                      ),
                      TextFormField(
                        initialValue: email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => email = v,
                      ),

                      // Dropdown type client
                      DropdownButtonFormField<String>(
                        value: type.isNotEmpty ? type : null,
                        items: [
                          'WHS_WHOLESALERS',
                          'HFS_HIGH_FREQUENCY_STORES',
                          'SMM_SUPERMARKETS',
                          'PERF_PERFUMERIES',
                          'LIVREUR',
                        ]
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value.replaceAll('_', ' ')),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setModalState(() => type = value ?? ''),
                        decoration:
                            const InputDecoration(labelText: 'Type de client'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Type obligatoire' : null,
                      ),

                      // Dropdown sélection de route
                      DropdownButtonFormField<int>(
                        value: selectedRouteId,
                        items: routes
                            .map((route) => DropdownMenuItem(
                                  value: route.id,
                                  child: Text(route.nom),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setModalState(() => selectedRouteId = value),
                        decoration:
                            const InputDecoration(labelText: 'Route assignée'),
                        validator: (v) =>
                            v == null ? 'Route obligatoire' : null,
                      ),

                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          Navigator.pop(context);

                          final newClient = Client(
                            id: client?.id ?? 0,
                            nom: nom,
                            adresse: adresse,
                            telephone: telephone,
                            email: email,
                            type: type,
                            derniereVisite: client?.derniereVisite ?? '',
                            routes: [],
                          );

                          try {
                            if (client == null) {
                              await ClientService.createClient(
                                  newClient, selectedRouteId!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Client créé avec succès')));
                            } else {
                              await ClientService.updateClient(
                                  client.id, newClient, selectedRouteId!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Client modifié avec succès')));
                            }
                            _loadClients();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur : $e')));
                          }
                        },
                        child: Text(client == null ? 'Créer' : 'Modifier'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Clients'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClients,
            tooltip: 'Actualiser',
          ),
        ],
      ),
     drawer: MainNavigationBar(
  userRole: widget.userRole,
  userName: widget.userName,
  onLogout: widget.onLogout,
  onNavigate: widget.onNavigate,
  currentRoute: ModalRoute.of(context)?.settings.name ?? "/home", // ✅ Détecte la page actuelle
  newOrdersCount: 5, // ✅ Exemple : badge avec 5 nouvelles commandes
),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClientForm(),
        tooltip: 'Ajouter un client',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un client...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterClients('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterClients,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Client>>(
              future: _clientsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Erreur : ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (filteredClients.isEmpty) {
                  return const Center(child: Text("Aucun client trouvé."));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredClients.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final client = filteredClients[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          client.nom,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📍 ${client.adresse}"),
                            Text("📞 ${client.telephone}"),
                            Text("📧 ${client.email}"),
                            Text("🏷️ Type : ${client.type}"),
                            Text(
                              client.routes.isNotEmpty
                                  ? "🏷️ Route(s) : ${client.routes.map((r) => r.nom).join(', ')}"
                                  : "🏷️ Route : Aucune",
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showClientForm(client: client),
                              tooltip: 'Modifier',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteClient(client.id),
                              tooltip: 'Supprimer',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
