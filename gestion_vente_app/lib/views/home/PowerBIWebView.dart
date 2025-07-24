import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;

import '../../services/auth_service.dart';
import '../../widgets/navigation_bar.dart';

class PowerBIView extends StatefulWidget {
  final String userRole;
  final String userName;
  final VoidCallback onLogout;
  final void Function(String route, {Map<String, dynamic>? arguments})
      onNavigate;

  const PowerBIView({
    super.key,
    required this.userRole,
    required this.userName,
    required this.onLogout,
    required this.onNavigate,
  });

  @override
  State<PowerBIView> createState() => _PowerBIViewState();
}

class _PowerBIViewState extends State<PowerBIView> {
  bool _drawerOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // 🔁 Enregistrer l'iframe une seule fois
    const String viewID = 'power-bi-html-view';
    ui.platformViewRegistry.registerViewFactory(
      viewID,
      (int viewId) => html.IFrameElement()
        ..      src="https://app.powerbi.com/reportEmbed?reportId=72c1b672-7af2-46da-a34a-4f1aa01bce0b&autoAuth=true&ctid=f93d5f40-88c0-4650-b8f2-cc4ec3ef6a10"
    ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      onDrawerChanged: (isOpen) {
        // ✅ détecter ouverture/fermeture du drawer
        setState(() {
          _drawerOpen = isOpen;
        });
      },
      appBar: AppBar(
        title: const Text('Dashboard Power BI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
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

      body: Stack(
        children: [
          // 👇 N'affiche l'iframe que si le drawer est fermé
          if (!_drawerOpen)
            const HtmlElementView(viewType: 'power-bi-html-view'),

          if (_drawerOpen)
            Positioned.fill(
              child: Container(
                color: Colors.white
                    .withOpacity(0.9), // fond léger pour bloquer l’iframe
                child: const Center(
                  child: Text(
                    "Navigation...",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
