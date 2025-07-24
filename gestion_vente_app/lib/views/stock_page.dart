  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:gestion_vente_app/models/produit_stock.dart';
  import '../../../models/stock_camion.dart';
  import '../../../models/produit.dart';
  import '../../../services/stock_service.dart';
  import '../../widgets/navigation_bar.dart';
  import '../services/produit_service.dart';

  class StockPage extends StatefulWidget {
    final String userRole;
    final String userName;
    final VoidCallback onLogout;
    final void Function(String route, {Map<String, dynamic>? arguments})
        onNavigate;

    const StockPage({
      super.key,
      required this.userRole,
      required this.userName,
      required this.onLogout,
      required this.onNavigate,
    });

    @override
    State<StockPage> createState() => _StockPageState();
  }

  class _StockPageState extends State<StockPage> {
    final StockService stockService = StockService();
    StockCamion? stock;
      List<StockCamion>? allStocks;

    bool isLoading = true;
    String? error;
    bool get isAdminOrSupervisor =>
        widget.userRole.toUpperCase() == 'ADMIN' || widget.userRole.toUpperCase() == 'SUPERVISEUR';

    @override
    void initState() {
      super.initState();
      if (isAdminOrSupervisor) {
        loadAllStocks();
      } else {
        loadStock();
      }
    }
    
  Future<void> loadAllStocks() async {
  setState(() {
    isLoading = true;
    error = null;
  });

  try {
    final result = await stockService.getTousLesStocks();

    if (result.isNotEmpty) {
      setState(() {
        allStocks = result;
        isLoading = false;
      });
    } else {
      setState(() {
        allStocks = [];
        isLoading = false;
        error = "Aucun stock disponible.";
      });
    }
  } catch (e) {
    setState(() {
      isLoading = false;
      error = "Erreur lors du chargement des stocks : $e";
    });
  }
}

Future<void> loadStock() async {
  setState(() {
    isLoading = true;
    error = null;
  });

  try {
    final result = await stockService.getMonStock();
    if (result != null) {
      for (var p in result.niveauxStock) {
      }
      setState(() {
        stock = result;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
        error = "Aucun stock retourné";
      });
    }
  } catch (e) {
    setState(() {
      isLoading = false;
     
    });
    
  }
}

 Future<bool> creerStock() async {

  try {
    final result = await stockService.creerMonStock();

    if (result != null) {
      setState(() {
        stock = result;
      });
      return true;
    } else {
 }
  } catch (e) {
}

  return false;
}

    Future<void> chargerProduit(int produitId, int quantite) async {
      if (stock == null) return;
      final success = await stockService.chargerStock(
        stockId: stock!.id,
        produitId: produitId,
        quantite: quantite,
      );
      if (success) {
        loadStock();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Produit chargé avec succès")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors du chargement du produit")),
        );
      }
    }

    Future<void> deduireProduit(int produitId, int quantite) async {
      final success = await stockService.deduireStock(
        produitId: produitId,
        quantite: quantite,
      );
      if (success) {
        loadStock();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Produit déduit avec succès")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de la déduction du produit")),
        );
      }
    }

    Future<void> _showModifierQuantiteDialog(ProduitStock produitStock) async {
      final quantiteController =
          TextEditingController(text: produitStock.quantite.toString());

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Modifier quantité de ${produitStock.nom}"),
            content: TextField(
              controller: quantiteController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Nouvelle quantité",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  quantiteController.dispose();
                  Navigator.of(context).pop();
                },
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nouvelleQuantite = int.tryParse(quantiteController.text);
                  if (nouvelleQuantite == null || nouvelleQuantite < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Veuillez saisir une quantité valide")),
                    );
                    return;
                  }

                  if (stock == null) return;

                  final success = await stockService.modifierStockManuellement(
                    stockId: stock!.id,
                    produitId: produitStock.produitId,
                    nouvelleQuantite: nouvelleQuantite,
                  );

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Quantité modifiée avec succès")),
                    );
                    loadStock();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Erreur lors de la modification")),
                    );
                  }
                  quantiteController.dispose();
                  Navigator.of(context).pop();
                },
                child: const Text("Modifier"),
              ),
            ],
          );
        },
      );
    }

    Future<void> supprimerProduit(int produitId) async {
      if (stock == null) return;

      final success = await stockService.supprimerProduitDuStock(
        stockId: stock!.id,
        produitId: produitId,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit supprimé avec succès')),
        );
        loadStock();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erreur lors de la suppression du produit')),
        );
      }
    }

    void _showAjouterProduitDialog() async {
      final quantiteController = TextEditingController();
      Produit? produitSelectionne;

      List<Produit> produitsDisponibles = [];
      try {
        produitsDisponibles = await ProduitService.getAllProduits();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors du chargement des produits : $e")),
        );
        return;
      }

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text("Ajouter un produit"),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: produitsDisponibles.length,
                          itemBuilder: (context, index) {
                            final p = produitsDisponibles[index];

                            ImageProvider? image;
                            try {
                              if (p.imageBase64 != null &&
                                  p.imageBase64!.isNotEmpty) {
                                image = MemoryImage(base64Decode(p.imageBase64!));
                              }
                            } catch (_) {
                              image = null;
                            }

                            return Card(
                              color: produitSelectionne == p
                                  ? Colors.blue.shade50
                                  : null,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                leading: image != null
                                    ? Image(
                                        image: image,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover)
                                    : const Icon(Icons.image_not_supported,
                                        size: 60),
                                title: Text(p.nom,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Marque: ${p.marque}"),
                                    Text("Prix: ${p.prixUnitaire} MAD"),
                                    Text("Description: ${p.description}",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                                selected: produitSelectionne == p,
                                selectedTileColor: Colors.blue.withOpacity(0.2),
                                onTap: () {
                                  setStateDialog(() {
                                    produitSelectionne = p;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: quantiteController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Quantité",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      quantiteController.dispose();
                      Navigator.of(context).pop();
                    },
                    child: const Text("Annuler"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (produitSelectionne == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Veuillez sélectionner un produit")),
                        );
                        return;
                      }
                      final qty = int.tryParse(quantiteController.text);
                      if (qty == null || qty <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Veuillez saisir une quantité valide")),
                        );
                        return;
                      }
                      chargerProduit(produitSelectionne!.id!, qty);
                      quantiteController.dispose();
                      Navigator.of(context).pop();
                    },
                    child: const Text("Ajouter"),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    
    Widget _buildStockList() {
      if (stock == null || stock!.niveauxStock.isEmpty) {
        return const Center(child: Text("Aucun produit dans le stock."));
      }

      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 600),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: stock!.niveauxStock.length,
          itemBuilder: (context, index) {
            final produit = stock!.niveauxStock[index];

            ImageProvider? image;
            try {
              if (produit.imageBase64 != null &&
                  produit.imageBase64!.isNotEmpty) {
                image = MemoryImage(base64Decode(produit.imageBase64!));
              }
            } catch (_) {
              image = null;
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (image != null)
                      Image(
                        image: image,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    else
                      const Icon(Icons.image_not_supported, size: 80),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(produit.nom,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          if (produit.marque != null)
                            Text("Marque : ${produit.marque}"),
                          if (produit.prixUnitaire != null)
                            Text("Prix : ${produit.prixUnitaire} MAD"),
                          Text("Quantité en stock : ${produit.quantite}"),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Colors.green, size: 30),
                          onPressed: () => chargerProduit(produit.produitId, 1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.orange, size: 30),
                          tooltip: "Modifier quantité manuellement",
                          onPressed: () => _showModifierQuantiteDialog(produit),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red, size: 30),
                          onPressed: () => deduireProduit(produit.produitId, 1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.grey, size: 30),
                          tooltip: "Supprimer le produit du stock",
                          onPressed: () => supprimerProduit(produit.produitId),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

  Widget _buildAllStocksView() {
    if (allStocks == null || allStocks!.isEmpty) {
      return const Center(child: Text("Aucun stock camion disponible."));
    }

    return ListView.builder(
    itemCount: allStocks!.length,
    padding: const EdgeInsets.all(12),
    itemBuilder: (context, index) {
      final stock = allStocks![index];

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 3,
        child: ExpansionTile(
          leading: const Icon(Icons.person, color: Colors.blue),
          title: Text(
            "Commerçant  : ${stock.chauffeur}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("Nombre de produits : ${stock.niveauxStock.length}"),
          children: stock.niveauxStock.map((produit) {
            ImageProvider? image;
            try {
              if (produit.imageBase64 != null &&
                  produit.imageBase64!.isNotEmpty) {
                image = MemoryImage(base64Decode(produit.imageBase64!));
              }
            } catch (_) {}

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: image != null
                    ? Image(
                        image: image,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image_not_supported, size: 50),
              ),
              title: Text(
                produit.nom,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (produit.marque != null)
                    Text("Marque : ${produit.marque}"),
                  if (produit.prixUnitaire != null)
                    Text("Prix : ${produit.prixUnitaire} MAD"),
                  Text("Quantité : ${produit.quantite}"),
                ],
              ),
            );
          }).toList(),
        ),
      );
    },
  );

  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("🚚 Mon Stock Camion"),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
   drawer: MainNavigationBar(
  userRole: widget.userRole,
  userName: widget.userName,
  onLogout: widget.onLogout,
  onNavigate: widget.onNavigate,
  currentRoute: ModalRoute.of(context)?.settings.name ?? "/home", // ✅ Détecte la page actuelle
  newOrdersCount: 5, // ✅ Exemple : badge avec 5 nouvelles commandes
),

    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : isAdminOrSupervisor
            ? _buildAllStocksView()
            : stock != null
                ? Stack(
                    children: [
                      _buildStockList(),
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: FloatingActionButton.extended(
                          onPressed: _showAjouterProduitDialog,
                          label: const Text("Ajouter produit"),
                          icon: const Icon(Icons.add),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ElevatedButton(
           onPressed: () async {
  final result = await creerStock();
  if (!mounted) return;

  if (result) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Stock créé avec succès")),
    );
  } else {
    // 💡 S'assurer que l'erreur est visible en plus du dialogue
    setState(() {
      error = "Impossible de créer le stock.";
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Erreur"),
        content: const Text("❌ Une erreur est survenue lors de la création du stock."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }
},
               child: const Text("Créer mon stock"),
                        ),
                      ],
                    ),
                  ),
  );
}

  }
