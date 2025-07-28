import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

class MainNavigationBar extends StatelessWidget {
  final String userRole;
  final String userName;
  final VoidCallback onLogout;
  final void Function(String route, {Map<String, dynamic>? arguments}) onNavigate;
  final String currentRoute;
  final int newOrdersCount;

  const MainNavigationBar({
    super.key,
    required this.userRole,
    required this.userName,
    required this.onLogout,
    required this.onNavigate,
    required this.currentRoute,
    this.newOrdersCount = 0,
  });

  bool get isAdmin => userRole == 'ADMIN';
  bool get isSuperviseur => userRole == 'SUPERVISEUR';
  bool get isVendeurDirect => userRole == 'VENDEURDIRECT';
  bool get canSeeStockCamion => isAdmin || isSuperviseur || isVendeurDirect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildUserHeader(context),
            
            const SizedBox(height: 8),
            
            // Section Navigation principale
            _buildSection(
              context,
              "🏠 Navigation",
              [
                _NavItem(Icons.home_outlined, "Accueil", "/home"),
                _NavItem(Icons.smart_toy_outlined, "Assistant IA", "/chatbot"),
                _NavItem(Icons.analytics_outlined, "Tableau Power BI", "/dashboard/powerbi"),
              ],
            ),

            // Section Ventes
            _buildSection(
              context,
              "🛍️ Gestion des ventes",
              [
                _NavItem(Icons.shopping_cart_outlined, "Commandes", "/commandes", 
                    badgeCount: newOrdersCount),
                _NavItem(Icons.event_available_outlined, "Visites", "/visites/calendrier"),
                _NavItem(Icons.groups_outlined, "Clients", "/admin/clients"),
                _NavItem(Icons.inventory_outlined, "Produits", "/admin/produits"),
                if (canSeeStockCamion)
                  _NavItem(Icons.local_shipping_outlined, "Stock camion", "/stock"),
              ],
            ),

            // Section Administration
            if (isSuperviseur || isAdmin)
              _buildSection(
                context,
                "⚙️ Administration",
                [
                  if (isSuperviseur || isAdmin)
                    _NavItem(Icons.person_search_outlined, "Vendeurs", "/admin/vendeurs"),
                  if (isAdmin) ...[
                    _NavItem(Icons.map_outlined, "Routes", "/admin/routes"),
                    _NavItem(Icons.local_offer_outlined, "Promotions", "/admin/promotions"),
                    _NavItem(Icons.admin_panel_settings_outlined, "Utilisateurs", "/admin/utilisateurs"),
                  ],
                ],
              ),

            const SizedBox(height: 20),
            
            // Bouton de déconnexion
            _buildLogoutButton(context),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// En-tête utilisateur amélioré
  Widget _buildUserHeader(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 35,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getRoleDisplayName(userRole),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section avec titre et éléments
  Widget _buildSection(BuildContext context, String title, List<_NavItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map((item) => _buildNavItem(context, item)),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Élément de navigation amélioré
  Widget _buildNavItem(BuildContext context, _NavItem item) {
    final bool isActive = currentRoute == item.route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            onNavigate(item.route, arguments: {
              'userRole': userRole,
              'userName': userName,
              'onLogout': onLogout,
              'onNavigate': onNavigate,
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).primaryColor.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Icône avec badge
                SizedBox(
                  width: 28,
                  child: item.badgeCount > 0
                      ? badges.Badge(
                          badgeContent: Text(
                            item.badgeCount > 99 ? '99+' : item.badgeCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          badgeStyle: badges.BadgeStyle(
                            badgeColor: Colors.red,
                            elevation: 2,
                          ),
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: isActive
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                          ),
                        )
                      : Icon(
                          item.icon,
                          size: 22,
                          color: isActive
                              ? Theme.of(context).primaryColor
                              : Colors.grey[600],
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? Theme.of(context).primaryColor
                          : Colors.grey[800],
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bouton de déconnexion stylisé
  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showLogoutDialog(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.logout_outlined,
                  color: Colors.red[600],
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  'Déconnexion',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dialog de confirmation de déconnexion
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
  }

  /// Affichage convivial du rôle
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Administrateur';
      case 'SUPERVISEUR':
        return 'Superviseur';
      case 'VENDEURDIRECT':
        return 'Vendeur Direct';
      default:
        return role;
    }
  }
}

/// Classe pour structurer les éléments de navigation
class _NavItem {
  final IconData icon;
  final String title;
  final String route;
  final int badgeCount;

  const _NavItem(this.icon, this.title, this.route, {this.badgeCount = 0});
}