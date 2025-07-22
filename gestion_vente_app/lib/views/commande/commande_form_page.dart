import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../models/ligne_commande_dto.dart';
import '../../../models/produit.dart';
import '../../../models/promotion.dart';
import '../../../services/commande_service.dart';
import '../../../services/client_service.dart';
import '../../../services/produit_service.dart';
import '../../../services/promotion_service.dart';
import '../../models/PromotionCadeauInfo.dart';
import '../../models/commande_dto.dart';
import '../../widgets/navigation_bar.dart';
import 'package:collection/collection.dart';

class CommandeFormPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final VoidCallback onLogout;
  final void Function(String route, {Map<String, dynamic>? arguments})
      onNavigate;

  const CommandeFormPage({
    Key? key,
    required this.userRole,
    required this.userName,
    required this.onLogout,
    required this.onNavigate,
  }) : super(key: key);

  @override
  State<CommandeFormPage> createState() => _CommandeFormPageState();
}

class _CommandeFormPageState extends State<CommandeFormPage> {
  int? _selectedClientId;
  int? _selectedVendeurId;
  DateTime _selectedDateLivraison = DateTime.now().add(const Duration(days: 1));
  List<LigneCommande> _lignes = [];
  List<Produit> _produits = [];
  List<DropdownMenuItem<int>> _clientsDropdown = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final clients = await ClientService.getAllClients();
      final produits = await ProduitService.getAllProduits();
      setState(() {
        _clientsDropdown = clients
            .map((c) => DropdownMenuItem(value: c.id!, child: Text(c.nom)))
            .toList();
        _produits = produits;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement : $e')),
      );
    }
  }

  void _ajouterProduit(Produit produit) {
    final index = _lignes.indexWhere((l) => l.produit.id == produit.id);
    setState(() {
      if (index >= 0) {
        _lignes[index] = LigneCommande(
          id: _lignes[index].id,
          produitId: produit.id!,
          quantite: _lignes[index].quantite + 1,
          produit: produit,
          produitOffert: false,
        );
      } else {
        _lignes.add(LigneCommande(
          id: null,
          produitId: produit.id!,
          quantite: 1,
          produit: produit,
          produitOffert: false,
        ));
      }
    });
  }

  void _retirerProduit(LigneCommande ligne) {
    final index = _lignes.indexWhere((l) => l.produit.id == ligne.produit.id);
    if (index < 0) return;
    setState(() {
      if (_lignes[index].quantite > 1) {
        _lignes[index] = LigneCommande(
          id: _lignes[index].id,
          produitId: ligne.produitId,
          quantite: _lignes[index].quantite - 1,
          produit: ligne.produit,
          produitOffert: ligne.produitOffert,
        );
      } else {
        _lignes.removeAt(index);
      }
    });
  }

  Future<void> _selectDateLivraison(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateLivraison,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDateLivraison) {
      setState(() {
        _selectedDateLivraison = picked;
      });
    }
  }


  Future<void> _soumettreCommande() async {
    if (_selectedClientId == null || _lignes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }
    double montantTotalAvantRemise = 0;
    double montantReduction = 0;
    for (var ligne in _lignes) {
      final produit = ligne.produit;
      final quantite = ligne.quantite;
      final sousTotal = produit.prixUnitaire * quantite;
      montantTotalAvantRemise += sousTotal;
      final isOffert = produit.promotions?.any((promotion) =>
              promotion.type == 'CADEAU' &&
              promotion.produitOffertNom?.trim().toLowerCase() ==
                  produit.nom.trim().toLowerCase()) ??
          false;
      if (isOffert) continue;
      if (produit.promotions != null) {
        for (final promo in produit.promotions!) {
          if (promo.tauxReduction > 0) {
            montantReduction += sousTotal * promo.tauxReduction;
          }
          if (promo.discountValue != null && promo.discountValue! > 0) {
            montantReduction += promo.discountValue! * quantite;
          }
        }
      }
    }
    double montantTotal = montantTotalAvantRemise - montantReduction;
    if (montantTotal < 0) montantTotal = 0;
    final commande = CommandeDTO(
      id: 0,
      dateCreation: DateTime.now().toIso8601String().split('T')[0],
      statut: 'EN_ATTENTE',
      clientId: _selectedClientId!,
      vendeurId: _selectedVendeurId,
      clientNom: '',
      vendeurNom: '',
      lignes: _lignes,
      dateLivraison: _selectedDateLivraison.toIso8601String().split('T')[0],
      montantReduction: montantReduction,
      montantTotalAvantRemise: montantTotalAvantRemise,
      montantTotal: montantTotal,
      promotionsCadeaux: _lignes
          .expand((ligne) => ligne.produit.promotions ?? [])
          .where((p) => p.type == 'CADEAU')
          .map((p) => PromotionCadeauInfo(
                produitOffertNom: p.produitOffertNom,
                produitConditionNom: p.produitConditionNom,
                quantiteCondition: p.quantiteCondition,
                promotionId: 0,
                quantite: 0,
              ))
          .toList(),
      promotionIds: _lignes
          .expand((ligne) => ligne.produit.promotions ?? [])
          .map((p) => p.id)
          .whereType<int>()
          .toSet()
          .toList(),
    );
    try {
      await CommandeService.createCommande(commande);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande créée avec succès !')),
      );
      Navigator.pop(context);
    } catch (e) {
      await _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
    }
  }
  double reductionPourProduit(LigneCommande ligne) {
    final produit = ligne.produit;
    final sousTotal = produit.prixUnitaire * ligne.quantite;
    final promotions = produit.promotions;
    if (promotions == null || promotions.isEmpty) return 0.0;
    final isOffert = promotions.any((promotion) =>
        promotion.type == 'CADEAU' &&
        promotion.produitOffertNom?.trim().toLowerCase() ==
            produit.nom.trim().toLowerCase());
    if (isOffert) {
      return 0.0;
    }
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

  double get _montantTotalAvantRemise {
    double total = 0;
    for (var ligne in _lignes) {
      total += ligne.produit.prixUnitaire * ligne.quantite;
    }
    return total;
  }

  double get _montantReduction {
    double reduction = 0;
    for (var ligne in _lignes) {
      reduction += reductionPourProduit(ligne);
    }
    return reduction;
  }

  double get _montantTotal {
    final total = _montantTotalAvantRemise - _montantReduction;
    return total < 0 ? 0 : total;
  }

  Future<void> _showErrorDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erreur'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer une Commande')),
     drawer: MainNavigationBar(
  userRole: widget.userRole,
  userName: widget.userName,
  onLogout: widget.onLogout,
  onNavigate: widget.onNavigate,
  currentRoute: ModalRoute.of(context)?.settings.name ?? "/home", // ✅ Détecte la page actuelle
  newOrdersCount: 5, // ✅ Exemple : badge avec 5 nouvelles commandes
),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Client'),
            items: _clientsDropdown,
            value: _selectedClientId,
            onChanged: (val) => setState(() => _selectedClientId = val),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Date de livraison : '),
              TextButton(
                onPressed: () => _selectDateLivraison(context),
                child: Text(
                  '${_selectedDateLivraison.toLocal()}'.split(' ')[0],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Produits disponibles :'),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _produits.map((p) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _ajouterProduit(p),
                    child: Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: p.imageBase64 != null
                                ? Image.memory(
                                    base64Decode(p.imageBase64!),
                                    height: 100,
                                    width: 180,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        size: 60,
                                        color: Colors.grey),
                                  )
                                : const Icon(Icons.image_not_supported,
                                    size: 60, color: Colors.grey),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.nom,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (p.marque != null && p.marque!.isNotEmpty)
                                    Text(
                                      p.marque!,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${p.prixUnitaire.toStringAsFixed(2)} DH',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (p.promotions != null &&
                                      p.promotions!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Promotions :',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                    ...p.promotions!.map((promo) => Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '• ${promo.nom} (${promo.type})',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black87),
                                            ),
                                            if (promo.type == 'CADEAU') ...[
                                              Text(
                                                '🎁 Produit offert : ${promo.produitOffertNom ?? "Inconnu"}',
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green),
                                              ),
                                              if (promo.quantiteCondition !=
                                                      null &&
                                                  promo.quantiteCondition! >
                                                      0) ...[
                                                Text(
                                                  '🎯 À partir de ${promo.quantiteCondition} unités',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.blueGrey,
                                                  ),
                                                ),
                                              ],
                                              if (promo.quantiteOfferte !=
                                                      null &&
                                                  promo.quantiteOfferte! > 0)
                                                Text(
                                                  'Quantité offerte : ${promo.quantiteOfferte}',
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green),
                                                ),
                                            ] else ...[
                                              if (promo.tauxReduction > 0)
                                                Text(
                                                  '-${(promo.tauxReduction * 100).toStringAsFixed(0)}%',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              if (promo.discountValue != null &&
                                                  promo.discountValue! > 0)
                                                Text(
                                                  '-${promo.discountValue!.toStringAsFixed(2)} DH / unité',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                            ],
                                            const SizedBox(height: 6),
                                          ],
                                        )),
                                  ],
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Lignes de commande :',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (_lignes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Aucun produit sélectionné.'),
            ),
          ..._lignes.map(
            (l) {
              final sousTotal = l.produit.prixUnitaire * l.quantite;
              final reduction = reductionPourProduit(l);
              final totalApres = sousTotal - reduction;
              return ListTile(
                title: Text('${l.produit.nom} x${l.quantite}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sous-total : ${sousTotal.toStringAsFixed(2)} DH'),
                    Text('Réduction : ${reduction.toStringAsFixed(2)} DH',
                        style: const TextStyle(color: Colors.green)),
                    Text(
                        'Total après remise : ${totalApres.toStringAsFixed(2)} DH'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _retirerProduit(l),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _ajouterProduit(l.produit),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
              'Total avant remise : ${_montantTotalAvantRemise.toStringAsFixed(2)} DH'),
          Text('Réduction : ${_montantReduction.toStringAsFixed(2)} DH'),
          Text('Total à payer : ${_montantTotal.toStringAsFixed(2)} DH'),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              onPressed: _soumettreCommande,
              child: const Text('Valider Commande'),
            ),
          ),
        ],
      ),
    );
  }

}
