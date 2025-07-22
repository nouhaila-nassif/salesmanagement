import 'package:flutter/material.dart';
import '../../models/utilisateur_response.dart';
import '../../models/create_utilisateur_request.dart';
import '../../models/update_utilisateur_request.dart';
import '../../services/utilisateur_service.dart';
import '../../widgets/navigation_bar.dart';

class GestionUtilisateursPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final VoidCallback onLogout;
final void Function(String route, {Map<String, dynamic>? arguments}) onNavigate;
  const GestionUtilisateursPage({
    super.key,
    required this.userRole,
    required this.userName,
    required this.onLogout,
    required this.onNavigate,
  });

  @override
  State<GestionUtilisateursPage> createState() => _GestionUtilisateursPageState();
}


class _GestionUtilisateursPageState extends State<GestionUtilisateursPage> {
  late Future<List<UtilisateurResponse>> utilisateurs;
List<UtilisateurResponse> superviseurs = [];
String selectedRole = '';
int? selectedSuperviseurId;
@override
void initState() {
  super.initState();
  _chargerUtilisateurs();
  _chargerSuperviseurs();
}
void _chargerSuperviseurs() async {
  final tous = await UtilisateurService.getAllUtilisateurs();
  setState(() {
    superviseurs = tous.where((u) => u.role == "SUPERVISEUR").toList();
  });
}
final TextEditingController _searchController = TextEditingController();
List<UtilisateurResponse> allUsers = [];
List<UtilisateurResponse> filteredUsers = [];
void _filterUtilisateurs(String query) {
  setState(() {
    filteredUsers = allUsers
        .where((u) => u.nomUtilisateur.toLowerCase().contains(query.toLowerCase()))
        .toList();
  });
}

void _chargerUtilisateurs() {
  setState(() {
    utilisateurs = UtilisateurService.getAllUtilisateurs().then((users) {
      allUsers = users;
      filteredUsers = users;
      return users;
    });
  });
}

  void _supprimer(int id) async {
    await UtilisateurService.supprimerUtilisateur(id);
    setState(() {
      _chargerUtilisateurs();
    });
  }

void _afficherFormulaire({UtilisateurResponse? utilisateur}) {
  final usernameController = TextEditingController(text: utilisateur?.nomUtilisateur ?? '');
  final passwordController = TextEditingController();
  selectedRole = utilisateur?.role ?? '';
  selectedSuperviseurId = null;

  bool _passwordVisible = false;

final TextEditingController telephoneController = TextEditingController(text: utilisateur?.telephone ?? '');
final TextEditingController emailController = TextEditingController(text: utilisateur?.email ?? '');

showDialog(
  context: context,
  builder: (context) => StatefulBuilder(
    builder: (context, setState) => AlertDialog(
      title: Text(utilisateur == null ? 'Créer Utilisateur' : 'Modifier Utilisateur'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Nom utilisateur'),
            ),
            TextField(
              controller: telephoneController,
              decoration: const InputDecoration(labelText: 'Téléphone'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                suffixIcon: IconButton(
                  icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
              ),
            ),
            if (utilisateur == null)
              DropdownButtonFormField<String>(
                value: selectedRole.isNotEmpty ? selectedRole : null,
                items: ['ADMIN', 'SUPERVISEUR']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                    selectedSuperviseurId = null;
                  });
                },
                decoration: const InputDecoration(labelText: 'Rôle'),
              ),
            if (utilisateur == null &&
                (selectedRole == "PREVENDEUR" || selectedRole == "VENDEURDIRECT"))
              DropdownButtonFormField<int>(
                value: selectedSuperviseurId,
                items: superviseurs
                    .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.nomUtilisateur),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSuperviseurId = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Superviseur'),
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
          onPressed: () async {
            try {
              if (utilisateur == null) {
                await UtilisateurService.creerUtilisateur(
                  CreateUtilisateurRequest(
                    username: usernameController.text,
                    password: passwordController.text,
                    role: selectedRole,
                    superviseurId: (selectedRole == "PREVENDEUR" || selectedRole == "VENDEURDIRECT")
                        ? selectedSuperviseurId
                        : null,
                    telephone: telephoneController.text,
                    email: emailController.text,
                  ),
                );
              } else {
                await UtilisateurService.modifierUtilisateur(
                  utilisateur.id,
                  UpdateUtilisateurRequest(
                    nomUtilisateur: usernameController.text,
                    motDePasse: passwordController.text,
                    telephone: telephoneController.text,
                    email: emailController.text,
                  ),
                );
              }

              Navigator.pop(context);
              if (mounted) {
                _chargerUtilisateurs();
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Erreur : $e")),
              );
            }
          },
          child: const Text('Valider'),
        ),
      ],
    ),
  ),
);

}


Widget buildUserListItem(UtilisateurResponse user) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade600,
        child: Text(
          user.nomUtilisateur.isNotEmpty ? user.nomUtilisateur[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      title: Text(
        user.nomUtilisateur,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rôle : ${user.role}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Téléphone : ${user.telephone ?? 'N/A'}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          Text(
            'Email : ${user.email ?? 'N/A'}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
        ],
      ),
      trailing: Wrap(
        spacing: 12,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            tooltip: 'Modifier',
            onPressed: () => _afficherFormulaire(utilisateur: user),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Supprimer',
            onPressed: () => _supprimer(user.id),
          ),
        ],
      ),
    ),
  );
}

Icon _getRoleIcon(String role) {
  switch (role.toUpperCase()) {
    case 'ADMIN':
      return const Icon(Icons.admin_panel_settings, color: Colors.redAccent);
    case 'SUPERVISEUR':
      return const Icon(Icons.supervisor_account, color: Colors.blueAccent);
    case 'PREVENDEUR':
      return const Icon(Icons.shopping_cart, color: Colors.green);
    case 'VENDEURDIRECT':
      return const Icon(Icons.delivery_dining, color: Colors.orange);
    default:
      return const Icon(Icons.person, color: Colors.grey);
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Gestion des utilisateurs'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _chargerUtilisateurs,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterUtilisateurs('');
                      },
                    )
                  : null,
            ),
            onChanged: _filterUtilisateurs,
          ),
        ),
        Expanded(
          child: FutureBuilder<List<UtilisateurResponse>>(
            key: ValueKey(DateTime.now()), // force rebuild
            future: utilisateurs,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Erreur : ${snapshot.error}'));
              }

              if (filteredUsers.isEmpty) {
                return const Center(child: Text('Aucun utilisateur trouvé.'));
              }

          return ListView.separated(
  padding: const EdgeInsets.all(12),
  separatorBuilder: (_, __) => const SizedBox(height: 10),
  itemCount: filteredUsers.length,
  itemBuilder: (context, index) {
    final user = filteredUsers[index];

    final Icon roleIcon = _getRoleIcon(user.role);

    return Card(
  elevation: 4,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: ListTile(
    leading: CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey.shade100,
      child: roleIcon,
    ),
    title: Text(
      user.nomUtilisateur,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rôle : ${user.role}',
          style: const TextStyle(color: Colors.black54),
        ),
        Text(
          'Email : ${user.email ?? "N/A"}',
          style: const TextStyle(color: Colors.black54),
        ),
        Text(
          'Téléphone : ${user.telephone ?? "N/A"}',
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    ),
    trailing: Wrap(
      spacing: 8,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () => _afficherFormulaire(utilisateur: user),
          tooltip: 'Modifier',
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _supprimer(user.id),
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
