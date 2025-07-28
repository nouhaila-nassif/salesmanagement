import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/commande_dto.dart';
import '../../models/client.dart';
import '../../models/ligne_commande_dto.dart';
import '../../models/utilisateur_response.dart';
import '../../services/client_service.dart';
import '../../services/commande_service.dart';
import '../../services/utilisateur_service.dart';
import '../../widgets/navigation_bar.dart';
import 'CommandeDetailsPage.dart';
import 'commande_form_page.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;

class ListeVentesPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final VoidCallback onLogout;
  final void Function(String route, {Map<String, dynamic>? arguments})
      onNavigate;

  const ListeVentesPage({
    super.key,
    required this.userRole,
    required this.userName,
    required this.onLogout,
    required this.onNavigate,
  });

  @override
  State<ListeVentesPage> createState() => _ListeVentesPageState();
}

class _ListeVentesPageState extends State<ListeVentesPage> {
  late Future<List<CommandeDTO>> _commandesFuture;
  int? _expandedCommandeId;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final List<LigneCommande> _lignes = [];

  @override
  void initState() {
    super.initState();
    _loadCommandes();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _loadCommandes() {
    if (!mounted) return;
    setState(() {
      _commandesFuture = CommandeService.getCommandes();
      _expandedCommandeId = null;
    });
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Non définie';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (_) {
      return date;
    }
  }

  Future<void> _approveCommande(int commandeId) async {
    try {
      await CommandeService.approveCommande(commandeId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande approuvée avec succès')),
      );
      _loadCommandes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'approbation : $e')),
      );
    }
  }

  bool _canApprove(String statut) {
    return ['SUPERVISEUR', 'RESPONSABLEUNITE', 'ADMIN']
            .contains(widget.userRole.toUpperCase()) &&
        statut.toUpperCase() != 'APPROUVEE';
  }

  Future<void> _confirmDeleteCommande(int commandeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer cette commande ?'),
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
        await CommandeService.deleteCommande(commandeId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande supprimée avec succès')),
        );
        _loadCommandes();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : $e')),
        );
      }
    }
  }

  Future<void> _confirmCancelCommande(int commandeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment annuler cette commande ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Confirmer', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CommandeService.cancelCommande(commandeId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande annulée avec succès')),
        );
        _loadCommandes();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Commandes'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCommandes,
            tooltip: 'Actualiser',
          ),
        ],
        automaticallyImplyLeading: true, // Toujours afficher le bouton menu
      ),
     drawer: MainNavigationBar(
  userRole: widget.userRole,
  userName: widget.userName,
  onLogout: widget.onLogout,
  onNavigate: widget.onNavigate,
  currentRoute: ModalRoute.of(context)?.settings.name ?? "/home", // ✅ Détecte la page actuelle
  newOrdersCount: 5, // ✅ Exemple : badge avec 5 nouvelles commandes
),

      body: FutureBuilder<List<CommandeDTO>>(
        future: _commandesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune commande trouvée'));
          }

          final commandes = snapshot.data!;
          final screenWidth = MediaQuery.of(context).size.width;

          if (screenWidth < 600) {
            return _buildMobileView(commandes);
          } else {
            return _buildDesktopView(commandes, screenWidth);
          }
        },
      ),
      floatingActionButton: (widget.userRole == 'VENDEURDIRECT' ||
              widget.userRole == 'ADMIN' ||
              widget.userRole == 'PREVENDEUR')
          ? FloatingActionButton(
              onPressed: () => _navigateToCreatePage(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

 Widget _buildMobileView(List<CommandeDTO> commandes) {
  return ListView.builder(
    controller: _verticalScrollController,
    itemCount: commandes.length,
    itemBuilder: (context, index) {
      final commande = commandes[index];
      final isExpanded = _expandedCommandeId == commande.id;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: () {
            setState(() {
              _expandedCommandeId = isExpanded ? null : commande.id;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text('Commande #${commande.id}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client: ${commande.clientNom}'),
                    Text('Créée le: ${_formatDate(commande.dateCreation)}'),
                    Text('Livraison: ${_formatDate(commande.dateLivraison)}'),
                    Text(
                        'Total: ${commande.montantTotal.toStringAsFixed(2)} DH'),
                    Text('Statut: ${commande.statut}'),
                  ],
                ),
                trailing: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
              ),
             if (isExpanded) ...[
  _buildCommandeDetails(commande, true),
 Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // ✅ Affichage du statut de la commande sous forme de Chip
      Chip(
        label: Text(
          commande.statut,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
        backgroundColor: _getStatusColor(commande.statut),
      ),

      // ✅ Icônes d'actions
      Row(
        children: [
          if (_canMarkAsDelivered(commande.statut))
            IconButton(
              icon: const Icon(Icons.local_shipping, color: Colors.teal),
              tooltip: 'Marquer comme livrée',
              onPressed: () => _markAsDelivered(commande.id),
            ),
          if (_canMarkAsNonLivree(commande))
            IconButton(
              icon: const Icon(Icons.local_shipping_outlined, color: Colors.redAccent),
              tooltip: 'Marquer comme non livrée',
              onPressed: () => _markAsNonLivree(commande.id),
            ),
          // IconButton(
          //   icon: const Icon(Icons.picture_as_pdf, color: Colors.purple),
          //   tooltip: 'Télécharger la facture',
          //   onPressed: () => generateAndDownloadPdfWeb(commande),
          // ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            tooltip: 'Modifier',
            onPressed: () => _navigateToEditPage(commande),
          ),
        ],
      ),
    ],
  ),
),

],

            ],
          ),
        ),
      );
    },
  );
}

Color _getStatusColor(String statut) {
  switch (statut) {
    case 'EN_ATTENTE':
      return Colors.orangeAccent;
    case 'VALIDEE':
      return Colors.blueAccent;
    case 'LIVREE':
      return Colors.green;
    case 'ANNULEE':
      return Colors.grey;
    case 'NON_LIVREE':
      return Colors.redAccent;
    default:
      return Colors.black;
  }
}


 Widget _buildDesktopView(List<CommandeDTO> commandes, double screenWidth) {
  final now = DateTime.now();

  return Column(
    children: [
      Expanded(
        child: Scrollbar(
          controller: _verticalScrollController,
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            scrollDirection: Axis.vertical,
            child: Scrollbar(
              controller: _horizontalScrollController,
              notificationPredicate: (_) => true,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: screenWidth,
                  ),
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowHeight: 48,
                    dataRowHeight: 56,
                    columns: [
                      const DataColumn(label: Text('ID')),
                      const DataColumn(label: Text('Date Création')),
                      const DataColumn(label: Text('Date Livraison')),
                      const DataColumn(label: Text('Client')),
                      if (screenWidth > 700)
                        const DataColumn(label: Text('Vendeur')),
                      const DataColumn(label: Text('Statut')),
                      if (screenWidth > 800)
                        const DataColumn(label: Text('Avant Remise')),
                      if (screenWidth > 800)
                        const DataColumn(label: Text('Réduction')),
                      const DataColumn(label: Text('Total')),
                      const DataColumn(label: Text('Actions')),
                    ],
                rows: commandes.map((commande) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _verifierEtMettreAJourStatut(commande);
  });

  final statutAffiche = commande.statut;

  return DataRow(
    cells: [
      DataCell(Text('${commande.id}')),
      DataCell(Text(_formatDate(commande.dateCreation))),
      DataCell(Text(_formatDate(commande.dateLivraison))),
      DataCell(
        Tooltip(
          message: commande.clientNom,
          child: SizedBox(
            width: 120,
            child: Text(
              commande.clientNom,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      if (screenWidth > 700)
        DataCell(
          Tooltip(
            message: commande.vendeurNom,
            child: SizedBox(
              width: 120,
              child: Text(
                commande.vendeurNom,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      DataCell(
        Chip(
          label: Text(
            statutAffiche,
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: _getStatusColor(statutAffiche),
        ),
      ),
      if (screenWidth > 800)
        DataCell(Text('${commande.montantTotalAvantRemise.toStringAsFixed(2)} DH')),
      if (screenWidth > 800)
        DataCell(Text('${commande.montantReduction.toStringAsFixed(2)} DH')),
      DataCell(Text('${commande.montantTotal.toStringAsFixed(2)} DH')),
      DataCell(_buildActionButtons(commande)),
    ],
  );
}).toList(),
  ),
                ),
              ),
            ),
          ),
        ),
      ),

      if (_expandedCommandeId != null)
        SizedBox(
          height: 300,
          child: SingleChildScrollView(
            child: _buildCommandeDetails(
              commandes.firstWhere((cmd) => cmd.id == _expandedCommandeId),
              false,
            ),
          ),
        ),
    ],
  );
}

Future<void> _verifierEtMettreAJourStatut(CommandeDTO commande) async {
final livraisonDate = DateTime.parse(commande.dateLivraison).toLocal();
final today = DateTime.now();
final dateDuJour = DateTime(today.year, today.month, today.day);

  final isEnRetard = commande.statut != 'LIVREE' &&
      commande.statut != 'ANNULEE' &&
      commande.statut != 'NON_LIVREE' &&
livraisonDate.isBefore(dateDuJour)
;


if (isEnRetard) {
  await CommandeService.updateCommandeStatut(commande.id, 'NON_LIVREE');
  setState(() {
    commande.statut = 'NON_LIVREE';
  });
}

}
bool _canMarkAsDelivered(String statut) {
  return statut == 'VALIDEE' ; // adapte selon ta logique métier
}

Future<void> _markAsDelivered(int commandeId) async {
  try {
    await CommandeService.changerStatutCommande(commandeId, 'LIVREE');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commande marquée comme livrée.')),
    );
            _loadCommandes();
 // recharge les données si nécessaire
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur : $e')),
    );
  }
}
void _markAsNonLivree(int commandeId) async {
  try {
    await CommandeService.updateCommandeStatut(commandeId, 'NON_LIVREE');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commande marquée comme non livrée.')),
    );
    _loadCommandes(); // Rafraîchir la liste
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur : ${e.toString()}')),
    );
  }
}
bool _canMarkAsNonLivree(CommandeDTO commande) {
  return commande.statut == 'VALIDEE';
}

Widget _buildActionButtons(CommandeDTO commande) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (_canApprove(commande.statut))
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          tooltip: 'Approuver',
          onPressed: () => _approveCommande(commande.id),
        ),
      IconButton(
        icon: const Icon(Icons.remove_red_eye),
        tooltip: 'Détails',
        onPressed: () {
          setState(() {
            _expandedCommandeId =
                _expandedCommandeId == commande.id ? null : commande.id;
          });
        },
      ),
if (_canMarkAsDelivered(commande.statut) && 
    widget.userRole != 'ADMIN' && widget.userRole != 'SUPERVISEUR')
  IconButton(
    icon: const Icon(Icons.local_shipping, color: Colors.teal),
    tooltip: 'Marquer comme livrée',
    onPressed: () => _markAsDelivered(commande.id),
  ),

if (_canMarkAsNonLivree(commande) && 
    widget.userRole != 'ADMIN' && widget.userRole != 'SUPERVISEUR')
  IconButton(
    icon: const Icon(Icons.local_shipping_outlined, color: Colors.redAccent),
    tooltip: 'Marquer comme non livrée',
    onPressed: () => _markAsNonLivree(commande.id),
  ),

       IconButton(
        icon: const Icon(Icons.picture_as_pdf, color: Colors.purple),
        tooltip: 'Télécharger la facture',
        onPressed: () => generateAndDownloadPdfWeb(commande),
    ),
      IconButton(
        icon: const Icon(Icons.edit, color: Colors.blue),
        tooltip: 'Modifier',
        onPressed: () => _navigateToEditPage(commande),
      ),
      if (widget.userRole == 'ADMIN' || widget.userRole == 'SUPERVISEUR') ...[
        IconButton(
          icon: const Icon(Icons.cancel, color: Colors.orange),
          tooltip: 'Annuler',
          onPressed: () => _confirmCancelCommande(commande.id),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          tooltip: 'Supprimer',
          onPressed: () => _confirmDeleteCommande(commande.id),
        ),
      ],
    ],
  );
}

  Future<Client?> fetchClientForCommande(CommandeDTO commande) async {
    try {
      List<Client> clients = await ClientService.getAllClients();
      return clients.firstWhere(
        (client) => client.id == commande.clientId,
        orElse: () => null as Client,
      );
    } catch (e) {
      print('Erreur récupération client : $e');
      return null;
    }
  }

  Future<UtilisateurResponse?> fetchVendeurForCommande(
      CommandeDTO commande) async {
    try {
      List<UtilisateurResponse> vendeurs =
          await UtilisateurService.getAllVendeurs();
      return vendeurs.firstWhere(
        (vendeur) => vendeur.id == commande.vendeurId,
        // ignore: cast_from_null_always_fails
        orElse: () => null as UtilisateurResponse,
      );
    } catch (e) {
      print('Erreur récupération vendeur : $e');
      return null;
    }
  }

double reductionPourProduit(LigneCommande ligne) {
  final produit = ligne.produit;
  final sousTotal = produit.prixUnitaire * ligne.quantite;
  final promotions = produit.promotions;
  
  if (promotions == null || promotions.isEmpty) return 0.0;

  final isOffert = promotions.any((promotion) =>
      promotion.type == 'CADEAU' &&
      (promotion.produitOffertNom?.trim().toLowerCase() ?? '') ==
          produit.nom.trim().toLowerCase());
  if (isOffert) return 0.0;

  double totalReduction = 0.0;
  for (final promotion in promotions) {
    if (promotion.tauxReduction > 0) {
      totalReduction += sousTotal * promotion.tauxReduction;
    }
    if (promotion.discountValue != null && promotion.discountValue! > 0) {
      totalReduction += promotion.discountValue! * ligne.quantite;
    }
  }

  return totalReduction;
}
Future<void> generateAndDownloadPdfWeb(CommandeDTO commande) async {
  final pdf = pw.Document();
  final ttf =
      pw.Font.ttf(await rootBundle.load('fonts/NotoSans-Regular.ttf'));
  final emojiFont =
      pw.Font.ttf(await rootBundle.load('fonts/NotoEmoji-Regular.ttf'));
  final client = await fetchClientForCommande(commande);
  final vendeur = await fetchVendeurForCommande(commande);

  pw.TextStyle emojiTextStyle({double size = 12, bool isBold = false}) {
    return pw.TextStyle(
      font: ttf,
      fontFallback: [emojiFont],
      fontSize: size,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: PdfColors.blueGrey800,
    );
  }

  final Uint8List logoBytes = await rootBundle
      .load('assets/logo.png')
      .then((v) => v.buffer.asUint8List());
  final logoImage = pw.MemoryImage(logoBytes);

  // Étape 1 : calcul du total des sous-totaux des lignes non offertes
  final lignesPayantes = commande.lignes.where((l) => !l.produitOffert).toList();
  final totalSousTotal = lignesPayantes.fold<double>(
    0.0,
    (sum, ligne) => sum + ligne.produit.prixUnitaire * ligne.quantite,
  );

  // Étape 2 : générer les lignes avec calcul par ligne
  final List<List<String>> tableData = [
    ...commande.lignes.map((ligne) {
      final isCadeau = ligne.produitOffert;
      final qte = isCadeau ? '${ligne.quantite} (offert)' : '${ligne.quantite}';
      final pu = '${ligne.produit.prixUnitaire.toStringAsFixed(2)} DH';

      final sousTotal = ligne.produit.prixUnitaire * ligne.quantite;

      final reduction = isCadeau || totalSousTotal == 0
          ? 0.0
          : (sousTotal / totalSousTotal) * commande.montantReduction;

      final totalApresRemise = sousTotal - reduction;

      String promosInfo = '';
      if (ligne.produit.promotions != null && ligne.produit.promotions!.isNotEmpty) {
        promosInfo = ligne.produit.promotions!
            .map((promo) {
              final taux = promo.tauxReduction != null
                  ? ' ${(promo.tauxReduction * 100).toStringAsFixed(0)}%'
                  : '';
              return '${promo.nom}$taux';
            })
            .join(', ');
      }

      // Puis tu ajoutes la chaîne promosInfo au nom du produit
      final produit = isCadeau
        ? '${ligne.produit.nom} (CADEAU)||Montant : 0.00 DH'
        : '${ligne.produit.nom.replaceAll('||', ' ')}'
          '${promosInfo.isNotEmpty ? ' | Promo: $promosInfo' : ''}'
          '||Montant : ${sousTotal.toStringAsFixed(2)} DH';

      return [
        qte,
        produit,
        pu,
        '${reduction.toStringAsFixed(2)} DH',
        '${totalApresRemise.toStringAsFixed(2)} DH',
      ];
    }),
    ...commande.promotionsCadeaux.map((cadeau) => [
      '${cadeau.quantite} (offert)',
      '${cadeau.produitOffertNom} (CADEAU)\nMontant : 0.00 DH',
      '0.00 DH',
      '0.00 DH',
      '0.00 DH',
    ]),
  ];

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        // --- En-tête: logo + vendeur + client ---
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Logo + vendeur (gauche)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Image(logoImage, height: 80),
                pw.SizedBox(height: 8),
                pw.Text('Commerçant :',
                    style: pw.TextStyle(
                        font: ttf,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900)),
                pw.Text(vendeur?.nomUtilisateur ?? commande.vendeurNom,
                    style: pw.TextStyle(
                        font: ttf,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold)),
              ],
            ),

            pw.Container(
              width: 240,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey50,
                border: pw.Border.all(color: PdfColors.blueGrey300, width: 1),
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(8)),
                boxShadow: [
                  pw.BoxShadow(
                    color: PdfColors.grey300,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 6, horizontal: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blueGrey200,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Text(
                      'Informations client',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Nom : ${client?.nom.isNotEmpty == true ? client!.nom : (commande.clientNom.isNotEmpty ? commande.clientNom : "Non renseigné")}',
                    style: pw.TextStyle(font: ttf, fontSize: 12),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Email : ${client?.email.isNotEmpty == true ? client!.email : "Non renseigné"}',
                    style: pw.TextStyle(font: ttf, fontSize: 12),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Téléphone : ${client?.telephone.isNotEmpty == true ? client!.telephone : "Non renseigné"}',
                    style: pw.TextStyle(font: ttf, fontSize: 12),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Adresse : ${client?.adresse.isNotEmpty == true ? client!.adresse : "Non renseigné"}',
                    style: pw.TextStyle(font: ttf, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 24),

        // --- Détails commande (numéro, statut, dates) ---
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('N° de Commande : ${commande.id}',
                    style: pw.TextStyle(
                        font: ttf,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text('Statut : ${commande.statut}',
                    style: pw.TextStyle(font: ttf, fontSize: 12)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                    'Date création : ${_formatDate(commande.dateCreation)}',
                    style: pw.TextStyle(font: ttf, fontSize: 12)),
                pw.Text(
                    'Date livraison : ${_formatDate(commande.dateLivraison)}',
                    style: pw.TextStyle(font: ttf, fontSize: 12)),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 28),

        // --- Tableau Articles + Récapitulatif ---
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.7),
          columnWidths: {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(5), // Produit élargi
            2: pw.FlexColumnWidth(2),
            3: pw.FlexColumnWidth(2),
            4: pw.FlexColumnWidth(2),
          },

          children: [
            // Entête
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.blueGrey100),
              children: [
                for (final header in [
                  'Qté',
                  'Produit',
                  'Tarif unitaire',
                  'Réduction',
                  'Total après remise'
                ])
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 8, horizontal: 6),
                    child: pw.Text(header,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                            color: PdfColors.blueGrey900)),
                  ),
              ],
            ),

            // Lignes articles
            ...tableData.asMap().entries.map((entry) {
              final idx = entry.key;
              final rowData = entry.value;
              final isCadeau = rowData[1].contains('(CADEAU)');
              final isAlternateRow = idx % 2 == 1 && !isCadeau;

              return pw.TableRow(
                decoration: isCadeau
                    ? pw.BoxDecoration(color: PdfColors.green100)
                    : (isAlternateRow
                        ? pw.BoxDecoration(color: PdfColors.grey100)
                        : null),
                children: [
                  for (int i = 0; i < rowData.length; i++)
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 8, horizontal: 6),
                      child: i == 1
                          ? pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  rowData[i].split('||')[0], // Nom produit
                                  style: isCadeau
                                      ? pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          color: PdfColors.green900,
                                          font: ttf,
                                          fontSize: 12,
                                        )
                                      : pw.TextStyle(
                                          font: ttf,
                                          fontSize: 12,
                                          color: PdfColors.black,
                                        ),
                                ),
                                pw.Text(
                                  rowData[i].split('||')[1], // Montant
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                    fontStyle: pw.FontStyle.italic,
                                  ),
                                ),
                              ],
                            )
                          : pw.Text(
                              rowData[i],
                              style: isCadeau
                                  ? pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.green900,
                                      font: ttf)
                                  : pw.TextStyle(font: ttf, color: PdfColors.black),
                            ),
                    ),
                ],
              );
            }),

            // Ligne résumé financier (avant remise, réduction, total TTC)
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.blueGrey50),
              children: [
                pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 8, horizontal: 6),
                    child: pw.Text('')),
                pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 8, horizontal: 6),
                    child: pw.Text('')),
                pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 8, horizontal: 6),
                    child: pw.Text('Réduction TOTALE',
                        style: pw.TextStyle(font: ttf, fontSize: 10))),
                pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 8, horizontal: 6),
                    child: pw.Text(
                        '${commande.montantReduction.toStringAsFixed(2)} DH',
                        style: pw.TextStyle(font: ttf, fontSize: 10))),
              ],
            ),
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.blueGrey100),
              children: [
                pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 10, horizontal: 6),
                    child: pw.Text('')),
                pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 10, horizontal: 6),
                    child: pw.Text('')),
                pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 10, horizontal: 6),
                    child: pw.Text('Total TTC',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                            font: ttf,
                            color: PdfColors.blue900))),
                pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 10, horizontal: 6),
                    child: pw.Text(
                        '${commande.montantTotal.toStringAsFixed(2)} DH',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                            font: ttf,
                            color: PdfColors.blue900))),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 24),

        // Promotions appliquées
        if (commande.promotionsCadeaux.isNotEmpty ||
            commande.promotionsAppliquees.isNotEmpty) ...[
          pw.Text('Promotions appliquées :',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 15,
                  font: ttf,
                  color: PdfColors.blueGrey900)),
          pw.SizedBox(height: 10),
        ],

        if (commande.promotionsCadeaux.isNotEmpty)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('🎁 Cadeaux (${commande.promotionsCadeaux.length})',
                  style: emojiTextStyle(isBold: true, size: 14)),
              pw.SizedBox(height: 6),
              ...commande.promotionsCadeaux.map((promo) => pw.Bullet(
                    text:
                        '${promo.quantite} × ${promo.produitOffertNom} offert(s) pour ${promo.quantiteCondition}+ ${promo.produitConditionNom}',
                    style: pw.TextStyle(font: ttf, color: PdfColors.black),
                  )),
              pw.SizedBox(height: 12),
            ],
          ),

        if (commande.promotionsAppliquees.isNotEmpty)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('🛍 Remises (${commande.promotionsAppliquees.length})',
                  style: emojiTextStyle(isBold: true, size: 14)),
              pw.SizedBox(height: 6),
              ...commande.promotionsAppliquees.map((promo) {
                final reduction = promo.tauxReduction != null
                    ? '${(promo.tauxReduction * 100).toStringAsFixed(0)}% de réduction'
                    : 'Offre spéciale';
                return pw.Bullet(
                    text: '${promo.nom} - $reduction',
                    style: pw.TextStyle(font: ttf, color: PdfColors.black));
              }),
            ],
          ),

        pw.SizedBox(height: 32),
      ],
      footer: (context) {
        final baseStyle =
            pw.TextStyle(fontSize: 8, color: PdfColors.grey600, font: ttf);

        return pw.Container(
          padding: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Dislog Group – Société Anonyme', style: baseStyle),
                  pw.Text(
                      'Zone Industrielle Ouled Saleh, Bouskoura, Casablanca 20100, Maroc',
                      style: baseStyle),
                  pw.Text('ICE : 002082324000004', style: baseStyle),
                  pw.Text('Capital social : 453 509 700 MAD',
                      style: baseStyle),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Signature  : ____________________',
                      style: baseStyle),
                  pw.Text(
                      'le ${_formatDate(DateTime.now().toIso8601String())}',
                      style: baseStyle),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

  final bytes = await pdf.save();
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..download = 'facture_${commande.id}.pdf'
    ..style.display = 'none';

  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
    

  Widget _buildCommandeDetails(CommandeDTO commande, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: isMobile
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails de la commande #${commande.id}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (!isMobile) ...[
            Row(
              children: [
                _buildDetailItem(
                    'Date création', _formatDate(commande.dateCreation)),
                const SizedBox(width: 20),
                _buildDetailItem(
                    'Date livraison', _formatDate(commande.dateLivraison)),
                const SizedBox(width: 20),
                _buildDetailItem('Client', commande.clientNom),
                const SizedBox(width: 20),
                _buildDetailItem('Vendeur', commande.vendeurNom),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDetailItem('Statut', commande.statut),
                const SizedBox(width: 20),
                _buildDetailItem('Avant remise',
                    '${commande.montantTotalAvantRemise.toStringAsFixed(2)} DH'),
                const SizedBox(width: 20),
                _buildDetailItem('Réduction',
                    '${commande.montantReduction.toStringAsFixed(2)} DH'),
                const SizedBox(width: 20),
                _buildDetailItem(
                    'Total', '${commande.montantTotal.toStringAsFixed(2)} DH',
                    isBold: true),
              ],
            ),
          ] else ...[
            _buildDetailItem(
                'Date création', _formatDate(commande.dateCreation)),
            _buildDetailItem(
                'Date livraison', _formatDate(commande.dateLivraison)),
            _buildDetailItem('Client', commande.clientNom),
            _buildDetailItem('Vendeur', commande.vendeurNom),
            _buildDetailItem('Statut', commande.statut),
            _buildDetailItem('Avant remise',
                '${commande.montantTotalAvantRemise.toStringAsFixed(2)} DH'),
            _buildDetailItem('Réduction',
                '${commande.montantReduction.toStringAsFixed(2)} DH'),
            _buildDetailItem(
                'Total', '${commande.montantTotal.toStringAsFixed(2)} DH',
                isBold: true),
          ],
          const SizedBox(height: 16),
          const Text(
            'Articles commandés:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(3),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
            },
            border: TableBorder.all(color: Colors.grey),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[200]),
                children: [
                  _buildTableHeader('Qté'),
                  _buildTableHeader('Produit'),
                  _buildTableHeader('Prix unitaire'),
                  _buildTableHeader('Total'),
                ],
              ),
              ..._buildLignesCommande(commande),
            ],
          ),
          // Promotions cadeaux dans un ExpansionTile
          if (commande.promotionsCadeaux.isNotEmpty ||
              commande.promotionsAppliquees.isNotEmpty) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              title: Text(
                'Détails des promotions (${commande.promotionsCadeaux.length + commande.promotionsAppliquees.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                if (commande.promotionsCadeaux.isNotEmpty) ...[
                  _buildPromotionSection(
                    icon: Icons.card_giftcard,
                    title: 'Cadeaux (${commande.promotionsCadeaux.length})',
                    items: commande.promotionsCadeaux
                        .map((promo) =>
                            '🎁 ${promo.quantite} × ${promo.produitOffertNom} offert(s) pour ${promo.quantiteCondition}+ ${promo.produitConditionNom}')
                        .toList(),
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                ],
                if (commande.promotionsAppliquees.isNotEmpty) ...[
                  _buildPromotionSection(
                    icon: Icons.discount,
                    title: 'Remises (${commande.promotionsAppliquees.length})',
                    items: commande.promotionsAppliquees
                        .map((promo) =>
                            // ignore: unnecessary_null_comparison
                            '🛍 ${promo.nom} - ${promo.tauxReduction != null ? '${(promo.tauxReduction * 100).toStringAsFixed(0)}% de réduction' : 'Offre spéciale'}')
                        .toList(),
                    color: Colors.blue,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPromotionSection({
    required IconData icon,
    required String title,
    required List<String> items,
    required MaterialColor color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin:
          const EdgeInsets.only(bottom: 8), // Marge pour séparer les sections
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête de la section
          Row(
            children: [
              Icon(icon, color: color[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color[800],
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Contenu scrollable
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: items.length > 3
                  ? 150
                  : double.infinity, // Défilement seulement si plus de 3 items
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: items.length > 3
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                return Text(
                  '• ${items[index]}',
                  style: TextStyle(
                    color: color[700],
                    fontSize: 13,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableRow> _buildLignesCommande(CommandeDTO commande) {
    List<TableRow> rows = [];

    // 1. Ajouter les lignes normales de la commande
    for (var ligne in commande.lignes) {
      final produit = ligne.produit;
      final bool isCadeau = ligne.produitOffert;

      final String quantiteStr =
          isCadeau ? '${ligne.quantite} (offert)' : '${ligne.quantite}';
      final String prixUnitaireStr = isCadeau
          ? '0.00 DH'
          : '${produit.prixUnitaire.toStringAsFixed(2)} DH';
      final String totalStr = isCadeau
          ? '0.00 DH'
          : '${(produit.prixUnitaire * ligne.quantite).toStringAsFixed(2)} DH';

      rows.add(TableRow(
        decoration: isCadeau ? BoxDecoration(color: Colors.green[50]) : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              quantiteStr,
              style: TextStyle(
                fontWeight: isCadeau ? FontWeight.bold : FontWeight.normal,
                color: isCadeau ? Colors.green[800] : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${produit.nom}${isCadeau ? ' 🎁' : ''}',
              style: TextStyle(
                fontWeight: isCadeau ? FontWeight.bold : FontWeight.normal,
                color: isCadeau ? Colors.green[800] : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              prixUnitaireStr,
              style: TextStyle(color: isCadeau ? Colors.green[700] : null),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              totalStr,
              style: TextStyle(color: isCadeau ? Colors.green[700] : null),
            ),
          ),
        ],
      ));
    }

    // 2. Ajouter les lignes pour les cadeaux des promotions
    for (var promotionCadeau in commande.promotionsCadeaux) {
      rows.add(TableRow(
        decoration: BoxDecoration(
          color: Colors.green[50],
          border: Border(
            left: BorderSide(color: Colors.green[400]!, width: 4),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${promotionCadeau.quantite} 🎁',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${promotionCadeau.produitOffertNom} (CADEAU)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                Text(
                  'Promotion: ${promotionCadeau.quantiteCondition}+ ${promotionCadeau.produitConditionNom}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'GRATUIT',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '0.00 DH',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ));
    }

    return rows;
  }

  Widget _buildDetailItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(
              text: '$label : ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
              style:
                  isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }


  void _navigateToCreatePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommandeFormPage(
          userRole: widget.userRole,
          userName: widget.userName,
          onLogout: widget.onLogout,
          onNavigate: widget.onNavigate,
        ),
      ),
    ).then((_) => _loadCommandes());
  }

  void _navigateToEditPage(CommandeDTO commande) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommandeEditPage(
          userRole: widget.userRole,
          userName: widget.userName,
          onLogout: widget.onLogout,
          onNavigate: widget.onNavigate,
          commande: commande,
        ),
      ),
    ).then((_) => _loadCommandes());
  }
}


