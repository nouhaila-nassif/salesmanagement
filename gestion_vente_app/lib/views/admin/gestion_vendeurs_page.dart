import 'package:flutter/material.dart';
import '../../models/utilisateur_response.dart';
import '../../models/create_utilisateur_request.dart';
import '../../models/update_utilisateur_request.dart';
import '../../services/utilisateur_service.dart';
import '../../widgets/navigation_bar.dart';

class GestionVendeursPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final VoidCallback onLogout;
  final void Function(String route, {Map<String, dynamic>? arguments})
      onNavigate;

  const GestionVendeursPage({
    super.key,
    required this.userRole,
    required this.userName,
    required this.onLogout,
    required this.onNavigate,
  });

  @override
  State<GestionVendeursPage> createState() => _GestionVendeursPageState();
}

class _GestionVendeursPageState extends State<GestionVendeursPage> {
  late Future<List<UtilisateurResponse>> _vendeursFuture;
  List<UtilisateurResponse> _superviseurs = [];
 
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  void _chargerDonnees() {
    setState(() {
      _isLoading = true;
      _vendeursFuture = _chargerVendeurs();
      _chargerSuperviseurs().then((_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    });
  }

  Future<List<UtilisateurResponse>> _chargerVendeurs() async {
    try {
      return widget.userRole == 'SUPERVISEUR'
          ? await UtilisateurService.getVendeursDuSuperviseurConnecte()
          : await UtilisateurService.getAllVendeurs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
      return [];
    }
  }

  Future<void> _chargerSuperviseurs() async {
    try {
      final tous = await UtilisateurService.getAllUtilisateurs();
      if (mounted) {
        setState(() {
          _superviseurs = tous.where((u) => u.role == "SUPERVISEUR").toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement superviseurs: $e')),
        );
      }
    }
  }

  Future<void> _supprimerVendeur(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce vendeur?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        await UtilisateurService.supprimerUtilisateur(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vendeur supprimé avec succès')),
          );
          _chargerDonnees();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _afficherFormulaire({UtilisateurResponse? utilisateur}) {
    final usernameController =
        TextEditingController(text: utilisateur?.nomUtilisateur ?? '');
    final passwordController = TextEditingController();
    final telephoneController =
        TextEditingController(text: utilisateur?.telephone ?? '');
    final emailController =
        TextEditingController(text: utilisateur?.email ?? '');

    String role = utilisateur?.role ?? 'VENDEURDIRECT';
    int? superviseurId = utilisateur?.superviseurId;

    bool passwordVisible = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
                utilisateur == null ? 'Nouveau Vendeur' : 'Modifier Vendeur'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom utilisateur',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: telephoneController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: !passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                            () => passwordVisible = !passwordVisible),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: ['PREVENDEUR', 'VENDEURDIRECT']
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => role = value!),
                    decoration: const InputDecoration(
                      labelText: 'Rôle',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: superviseurId,
                    items: _superviseurs
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.nomUtilisateur),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => superviseurId = value),
                    decoration: const InputDecoration(
                      labelText: 'Superviseur',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                onPressed: () async {
                  if (usernameController.text.trim().isEmpty ||
                      telephoneController.text.trim().isEmpty ||
                      emailController.text.trim().isEmpty ||
                      (utilisateur == null &&
                          passwordController.text.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Tous les champs sont obligatoires.')),
                    );
                    return;
                  }

                  try {
                    setState(() => _isLoading = true);
                    if (utilisateur == null) {
                      // Création
                      await UtilisateurService.creerUtilisateur(
                        CreateUtilisateurRequest(
                          username: usernameController.text,
                          password: passwordController.text,
                          role: role,
                          superviseurId: superviseurId,
                          telephone: telephoneController.text,
                          email: emailController.text,
                        ),
                      );
                    } else {
                      // Modification
                      await UtilisateurService.modifierUtilisateur(
                        utilisateur.id,
                        UpdateUtilisateurRequest(
                          nomUtilisateur: usernameController.text.trim(),
                          motDePasse: passwordController.text.isNotEmpty
                              ? passwordController.text
                              : null,
                          telephone: telephoneController.text.trim(),
                          email: emailController.text.trim(),
                          superviseurId: superviseurId,
                        ),
                      );
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      _chargerDonnees();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(utilisateur == null
                              ? 'Vendeur créé avec succès'
                              : 'Vendeur modifié avec succès'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Erreur : $e")),
                      );
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: const Text('Enregistrer',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Vendeurs'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargerDonnees,
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
        onPressed: () => _afficherFormulaire(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher un vendeur',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UtilisateurResponse>>(
              future: _vendeursFuture,
              builder: (context, snapshot) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur de chargement',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _chargerDonnees,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                final vendeurs = snapshot.data ?? [];

                if (vendeurs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Aucun vendeur trouvé'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _afficherFormulaire(),
                          child: const Text('Ajouter un vendeur'),
                        ),
                      ],
                    ),
                  );
                }

                final searchTerm = _searchController.text.toLowerCase();
                final filteredList = vendeurs.where((vendeur) {
                  return vendeur.nomUtilisateur
                          .toLowerCase()
                          .contains(searchTerm) ||
                      vendeur.role.toLowerCase().contains(searchTerm) ||
                      (vendeur.superviseurNom ?? '')
                          .toLowerCase()
                          .contains(searchTerm);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final vendeur = filteredList[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    vendeur.nomUtilisateur,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      vendeur.role,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor:
                                        _getRoleColor(vendeur.role),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (vendeur.telephone != null &&
                                  vendeur.telephone!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'Téléphone : ${vendeur.telephone}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              if (vendeur.email != null &&
                                  vendeur.email!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'Email : ${vendeur.email}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'Superviseur: ${vendeur.superviseurNom ?? 'Aucun superviseur'}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _afficherFormulaire(
                                        utilisateur: vendeur),
                                    tooltip: 'Modifier',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _supprimerVendeur(vendeur.id),
                                    tooltip: 'Supprimer',
                                  ),
                                ],
                              ),
                            ],
                          ),
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'VENDEURDIRECT':
        return Colors.teal[100]!;
      case 'PREVENDEUR':
        return Colors.orange[100]!;
      default:
        return Colors.grey[200]!;
    }
  }
}
