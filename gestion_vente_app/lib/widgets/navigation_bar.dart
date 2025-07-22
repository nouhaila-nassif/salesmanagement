import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

class MainNavigationBar extends StatelessWidget {
  final String userRole;
  final String userName;
  final VoidCallback onLogout;
  final void Function(String route, {Map<String, dynamic>? arguments}) onNavigate;
  final String currentRoute; // ✅ Pour savoir quelle page est active
  final int newOrdersCount; // ✅ Exemple de badge (nouvelle commande)

  const MainNavigationBar({
    Key? key,
    required this.userRole,
    required this.userName,
    required this.onLogout,
    required this.onNavigate,
    required this.currentRoute,
    this.newOrdersCount = 0,
  }) : super(key: key);

  bool get isAdmin => userRole == 'ADMIN';
  bool get isSuperviseur => userRole == 'SUPERVISEUR';
  bool get isVendeurDirect => userRole == 'VENDEURDIRECT';
  bool get canSeeStockCamion => isAdmin || isSuperviseur || isVendeurDirect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            accountName: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              userRole,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Theme.of(context).primaryColor),
            ),
          ),

          _sectionTitle("🛍️ Gestion des ventes"),

          _navItem(context, Icons.home, "Accueil", "/home"),
          _navItem(context, Icons.chat_bubble_outline, "Assistant IA", "/chatbot"),
          _navItem(context, Icons.dashboard_outlined, "Tableau Power BI", "/dashboard/powerbi"),

          _navItem(
            context,
            Icons.shopping_cart_outlined,
            "Commandes",
            "/commandes",
          ),
          _navItem(context, Icons.event, "Visites", "/visites/calendrier"),
          _navItem(context, Icons.group_outlined, "Clients", "/admin/clients"),
          _navItem(context, Icons.inventory_2_outlined, "Produits", "/admin/produits"),

          if (canSeeStockCamion)
            _navItem(context, Icons.local_shipping_outlined, "Stock camion", "/stock"),

          if (isSuperviseur)
            _navItem(context, Icons.person_search_outlined, "Vendeurs", "/admin/vendeurs"),

          if (isAdmin) ...[
            _navItem(context, Icons.map_outlined, "Routes", "/admin/routes"),
            _navItem(context, Icons.person_search_outlined, "Vendeurs", "/admin/vendeurs"),
            _navItem(context, Icons.local_offer_outlined, "Promotions", "/admin/promotions"),
            _navItem(context, Icons.supervised_user_circle_outlined, "Utilisateurs", "/admin/utilisateurs"),
          ],

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout_outlined, color: Colors.redAccent),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.redAccent)),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }

  /// ✅ TITRE DE SECTION
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// ✅ NAVIGATION ITEM MODERNE (hover + sélection active + badge)
  Widget _navItem(
    BuildContext context,
    IconData icon,
    String title,
    String route, {
    int badgeCount = 0,
  }) {
    final bool isActive = currentRoute == route;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onNavigate(route, arguments: {
          'userRole': userRole,
          'userName': userName,
          'onLogout': onLogout,
          'onNavigate': onNavigate,
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).primaryColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // ✅ Icône avec badge
            badgeCount > 0
                ? badges.Badge(
                    badgeContent: Text(
                      badgeCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    child: Icon(icon,
                        color: isActive
                            ? Theme.of(context).primaryColor
                            : Colors.blueGrey),
                  )
                : Icon(
                    icon,
                    color: isActive
                        ? Theme.of(context).primaryColor
                        : Colors.blueGrey,
                  ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
