import 'package:flutter/material.dart';
import '../../models/visite_request.dart';
import '../../services/visite_service.dart';

import '../../widgets/calendrier_widget.dart';
import '../../widgets/navigation_bar.dart';

class CalendrierVisitesPage extends StatefulWidget {
   final String userRole;
  final String userName;
  final VoidCallback onLogout;
  final void Function(String route, {Map<String, dynamic>? arguments}) onNavigate;

  const CalendrierVisitesPage({  super.key,
    required this.userRole,
    required this.userName,
    required this.onLogout,
    required this.onNavigate,});

  @override
  State<CalendrierVisitesPage> createState() => _CalendrierVisitesPageState();
}

class _CalendrierVisitesPageState extends State<CalendrierVisitesPage> {
  late Future<List<Visite>> _futureVisites;
  final ApiService _apiService = ApiService();
bool _isLoadingPlanification = false;

Future<void> _planifierVisitesAutomatiques() async {
  setState(() {
    _isLoadingPlanification = true;
  });

  try {
    // Appelle la méthode API qui renvoie la liste des visites créées
    final visitesCreees = await _apiService.getPlanificationVisites();

    // Recharge la liste des visites affichées
    _loadVisites();

    if (visitesCreees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune nouvelle visite n’a été créée')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${visitesCreees.length} visite(s) automatique(s) créée(s) avec succès'),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la planification: $e')),
    );
  } finally {
    setState(() {
      _isLoadingPlanification = false;
    });
  }
}

  @override
  void initState() {
    super.initState();
    _loadVisites();
  }

  void _loadVisites() {
    setState(() {
      _futureVisites = _apiService.getProchainesVisitesCritiques();
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Calendrier des visites'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh),
          tooltip: 'Rafraîchir',
          onPressed: _loadVisites,
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

    body: Column(
      children: [
        if (widget.userRole.toUpperCase() == 'ADMIN')
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: _isLoadingPlanification
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.playlist_add_check),
              label: Text('Planifier visites automatiques'),
              onPressed: _isLoadingPlanification ? null : _planifierVisitesAutomatiques,
            ),
          ),
        Expanded(
          child: FutureBuilder<List<Visite>>(
            future: _futureVisites,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erreur : ${snapshot.error}'),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: Icon(Icons.refresh),
                        label: Text('Réessayer'),
                        onPressed: _loadVisites,
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Aucune visite programmée.'));
              } else {
                return CalendrierWidget(visites: snapshot.data!);
              }
            },
          ),
        ),
      ],
    ),
  );
}

}

