import 'package:flutter/material.dart';
import 'package:gestion_vente_app/models/commande_dto.dart';
import 'package:gestion_vente_app/views/home/PowerBIWebView.dart';
import '../views/admin/liste_clients_page.dart';
import '../views/admin/liste_produits_page.dart';
import '../views/admin/liste_promotions_page.dart';
import '../views/admin/route_list_page.dart';
import '../views/commande/CommandeDetailsPage.dart';
import '../views/commande/commande_form_page.dart';
import '../views/commande/liste_ventes_page.dart';
import '../views/login/login_page.dart';
import '../views/home/home_page.dart';
import '../views/admin/gestion_utilisateurs_page.dart';
import '../views/admin/gestion_vendeurs_page.dart';
import '../views/stock_page.dart';
import '../views/visites/calendrier_visites_page.dart';
import '../widgets/chatboot.dart';
import '../widgets/ia_chat_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const LoginPage(),
  '/ia': (context) => IAChatPage(),
 '/commande/edit': (context) {
  final settings = ModalRoute.of(context)!.settings;
  final args = settings.arguments as Map<String, dynamic>?;

  if (args == null || !args.containsKey('commande')) {
    // Tu peux retourner une page d'erreur ou une page vide
    return Scaffold(
      body: Center(child: Text('Erreur: paramètres manquants pour éditer la commande')),
    );
  }

  final commande = args['commande'] as CommandeDTO;
  return CommandeEditPage(
    userRole: args['userRole'] ?? '',
    userName: args['userName'] ?? '',
    onLogout: args['onLogout'] ?? () {},
    onNavigate: args['onNavigate'] ?? (route, {arguments}) {},
    commande: commande,
  );
},
// '/chatbot': (context)  {
//   final args =
//         ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
//     return  ChatbotPage(
//        userRole: args['userRole'],
//       userName: args['userName'],
//       onLogout: args['onLogout'],
//       onNavigate: args['onNavigate'],
//         );
//   },
'/chatbot': (context) => const ChatbotPage(),

  
'/home': (context)  {
  final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return HomePage(
      userRole: args['userRole'] ?? '',
      userName: args['userName'] ?? '',
      onLogout: args['onLogout'] ?? () {},
      onNavigate: args['onNavigate'] ??
          (route, {arguments}) {}, // Adapté pour matcher le type
    );
  },



  '/commande/create': (context) {
      final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return CommandeFormPage(
          userRole: args['userRole'] ?? '',
      userName: args['userName'] ?? '',
      onLogout: args['onLogout'] ?? () {},
      onNavigate: args['onNavigate'] ??
          (route, {arguments}) {}, // Adapté pour matcher le type
    );
  },
  '/stock': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return StockPage(
       userRole: args['userRole'] ?? '',
      userName: args['userName'] ?? '',
      onLogout: args['onLogout'] ?? () {},
      onNavigate: args['onNavigate'] ??
          (route, {arguments}) {}, // Adapté pour matcher le type
    );
  },
'/commandes': (context) {
  final settings = ModalRoute.of(context)!.settings;
  final args = settings.arguments as Map<String, dynamic>?;

  return ListeVentesPage(
    userRole: args?['userRole'] ?? '',
    userName: args?['userName'] ?? '',
    onLogout: args?['onLogout'] ?? () {},
    onNavigate: args?['onNavigate'] ?? (route, {arguments}) {},
  );
},
'/dashboard/powerbi': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

  return PowerBIView(
    userRole: args?['userRole'] ?? '',
    userName: args?['userName'] ?? '',
    onLogout: args?['onLogout'] ?? () {},
    onNavigate: args?['onNavigate'] ?? (route, {arguments}) {
      debugPrint('Navigation manquante pour $route');
    },
  );
},
'/visites/calendrier': (context) {
  final settings = ModalRoute.of(context)!.settings;
  final args = settings.arguments as Map<String, dynamic>?;

  return CalendrierVisitesPage(
    userRole: args?['userRole'] ?? '',
    userName: args?['userName'] ?? '',
    onLogout: args?['onLogout'] ?? () {},
    onNavigate: args?['onNavigate'] ?? (route, {arguments}) {},
  );
},




  '/admin/utilisateurs': (context) {
   final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // Option 1 : Afficher un message d'erreur simple
    // return Scaffold(
    //   body: Center(child: Text('Erreur: paramètres manquants')),
    // );

    // Option 2 : Ou retourner une page par défaut (ex: page de connexion)
    

  return GestionUtilisateursPage(
      userRole: args['userRole'] ?? '',
      userName: args['userName'] ?? '',
      onLogout: args['onLogout'] ?? () {},
      onNavigate: args['onNavigate'] ??
          (route, {arguments}) {}, // Adapté pour matcher le type
    );
},

  '/admin/promotions': (context) {
    final settings = ModalRoute.of(context)!.settings;
    final args = settings.arguments as Map<String, dynamic>?;

    return ListePromotionsPage(
      userRole: args?['userRole'] ?? '',
      userName: args?['userName'] ?? '',
      onLogout: args?['onLogout'] ?? () {},
      onNavigate: args?['onNavigate'] ??
          (route, {arguments}) {}, // Adapté pour matcher le type
    );
  },
  '/admin/vendeurs': (context) {
    final settings = ModalRoute.of(context)!.settings;
    final args = settings.arguments as Map<String, dynamic>?;
    return GestionVendeursPage(
       userRole: args?['userRole'] ?? '',
      userName: args?['userName'] ?? '',
      onLogout: args?['onLogout'] ?? () {},
      onNavigate: args?['onNavigate'] ??
          (route, {arguments}) {}, // Adapté pour matcher le type
    );
  },
  '/admin/clients': (context) {
    final settings = ModalRoute.of(context)!.settings;
    final args = settings.arguments as Map<String, dynamic>?;
    return ListeClientsPage(
       userRole: args?['userRole'] ?? '',
      userName: args?['userName'] ?? '',
      onLogout: args?['onLogout'] ?? () {},
      onNavigate: args?['onNavigate'] ??
          (route, {arguments}) {}, // Adapté pour matcher le type
    );
  },
  '/admin/produits': (context) {
    final settings = ModalRoute.of(context)!.settings;
    final args = settings.arguments as Map<String, dynamic>?;

    return ListeProduitsPage(
        userRole: args?['userRole'] ?? '',
      userName: args?['userName'] ?? '',
      onLogout: args?['onLogout'] ?? () {},
      onNavigate: args?['onNavigate'] ??
          (route, {arguments}) {}, // Adapté pour matcher le type
    );
  },
  '/admin/routes': (context) {
    final settings = ModalRoute.of(context)!.settings;
    final args = settings.arguments as Map<String, dynamic>?;

    return RouteListPage(
      userRole: args?['userRole'] ?? '',
      userName: args?['userName'] ?? '',
      onLogout: args?['onLogout'] ?? () {},
      onNavigate: args?['onNavigate'] ??
          (route, {arguments}) {}, // Adapté pour matcher le type
    );
  },
};
