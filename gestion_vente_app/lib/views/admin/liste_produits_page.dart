import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gestion_vente_app/widgets/navigation_bar.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/categorie_produit.dart';
import '../../models/produit.dart';
import '../../services/produit_service.dart';
import '../../utils/secure_storage.dart';

class ListeProduitsPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final VoidCallback onLogout;
  final void Function(String route, {Map<String, dynamic>? arguments})
      onNavigate;
  const ListeProduitsPage({
    super.key,
    required this.userRole,
    required this.userName,
    required this.onLogout,
    required this.onNavigate,
  });

  @override
  State<ListeProduitsPage> createState() => _ListeProduitsPageState();
}

class _ListeProduitsPageState extends State<ListeProduitsPage> {
  late Future<List<Produit>> _produitsFuture;

  @override
  void initState() {
    super.initState();
    _isAdminFuture = SecureStorage.isAdmin();
    _loadProduits();
  }

  void _loadProduits() {
    setState(() {
      _produitsFuture = ProduitService.getAllProduits();
    });
  }

  Future<void> _refreshProduits() async {
    _loadProduits();
    await _produitsFuture;
  }

  Future<void> _showActions(BuildContext context, Produit produit) async {
    final isAdmin = await SecureStorage.isAdmin();

    if (!isAdmin) {
      // Optionnel : message pour informer que c'est réservé aux admins
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Action réservée aux administrateurs")),
      );
      return; // Ne pas ouvrir la modal si pas admin
    }

    // Si admin, on affiche le menu d'actions
    showModalBottomSheet(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Modifier"),
                onTap: () {
                  Navigator.pop(context);
                  _showModifierProduitModal(context, produit);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Supprimer",
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Confirmation"),
                      content:
                          Text("Supprimer le produit « ${produit.nom} » ?"),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Annuler")),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Supprimer")),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ProduitService.deleteProduit(produit.id!);
                    _refreshProduits();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAjoutProduitModal(BuildContext context) async {
    final isAdmin = await SecureStorage.isAdmin();

    if (!isAdmin) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Action réservée aux administrateurs")),
      );
      return; // on ne montre pas la modal
    }
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController();
    final marqueController = TextEditingController();
    final prixController = TextEditingController();
    final descriptionController = TextEditingController();
    String? imageBase64;
    int? selectedCategorieId;

    Future<List<CategorieProduit>>? categoriesFuture =
        ProduitService.getCategories();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: StatefulBuilder(
            builder:
                (BuildContext context, void Function(void Function()) state) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Ajouter un produit",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      TextFormField(
                        controller: nomController,
                        decoration:
                            const InputDecoration(labelText: "Nom du produit"),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Champ requis'
                            : null,
                      ),
                      TextFormField(
                        controller: marqueController,
                        decoration: const InputDecoration(labelText: "Marque"),
                      ),
                      TextFormField(
                        controller: prixController,
                        decoration:
                            const InputDecoration(labelText: "Prix unitaire"),
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Champ requis'
                            : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration:
                            const InputDecoration(labelText: "Description"),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<List<CategorieProduit>>(
                        future: categoriesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Text(
                                "Impossible de charger les catégories");
                          }
                          final categories = snapshot.data!;
                          return DropdownButtonFormField<int>(
                            decoration:
                                const InputDecoration(labelText: "Catégorie"),
                            value: selectedCategorieId,
                            items: categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat.id,
                                child: Text(cat.nom),
                              );
                            }).toList(),
                            onChanged: (val) => state(() {
                              selectedCategorieId = val!;
                            }),
                            validator: (value) =>
                                value == null ? 'Sélection obligatoire' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (picked != null) {
                            final bytes = await picked.readAsBytes();
                            state(() {
                              imageBase64 = base64Encode(bytes);
                            });
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: const Text("Ajouter une image"),
                      ),
                      if (imageBase64 != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Image.memory(
                            base64Decode(imageBase64!),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState?.validate() != true) return;

                          if (selectedCategorieId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Veuillez sélectionner une catégorie")),
                            );
                            return;
                          }

                          final produit = Produit(
                            nom: nomController.text,
                            marque: marqueController.text,
                            prixUnitaire:
                                double.tryParse(prixController.text) ?? 0,
                            imageBase64: imageBase64,
                            description: descriptionController.text,
                            categorieId: selectedCategorieId!,
                          );

                          try {
                            await ProduitService.createProduit(produit);
                            Navigator.pop(ctx);
                            _refreshProduits();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Produit ajouté")),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Erreur : $e")),
                            );
                          }
                        },
                        child: const Text("Ajouter"),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showModifierProduitModal(BuildContext context, Produit produit) {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController(text: produit.nom);
    final marqueController = TextEditingController(text: produit.marque);
    final prixController =
        TextEditingController(text: produit.prixUnitaire.toString());
    final descriptionController =
        TextEditingController(text: produit.description);
    String? imageBase64 = produit.imageBase64;
    int? selectedCategorieId = produit.categorieId;

    Future<List<CategorieProduit>>? categoriesFuture =
        ProduitService.getCategories();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: StatefulBuilder(
            builder:
                (BuildContext context, void Function(void Function()) state) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Modifier le produit",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      TextFormField(
                        controller: nomController,
                        decoration:
                            const InputDecoration(labelText: "Nom du produit"),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Champ requis'
                            : null,
                      ),
                      TextFormField(
                        controller: marqueController,
                        decoration: const InputDecoration(labelText: "Marque"),
                      ),
                      TextFormField(
                        controller: prixController,
                        decoration:
                            const InputDecoration(labelText: "Prix unitaire"),
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Champ requis'
                            : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration:
                            const InputDecoration(labelText: "Description"),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<List<CategorieProduit>>(
                        future: categoriesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Text(
                                "Impossible de charger les catégories");
                          }
                          final categories = snapshot.data!;
                          return DropdownButtonFormField<int>(
                            decoration:
                                const InputDecoration(labelText: "Catégorie"),
                            value: selectedCategorieId,
                            items: categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat.id,
                                child: Text(cat.nom),
                              );
                            }).toList(),
                            onChanged: (val) => state(() {
                              selectedCategorieId = val!;
                            }),
                            validator: (value) =>
                                value == null ? 'Sélection obligatoire' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (picked != null) {
                            final bytes = await picked.readAsBytes();
                            state(() {
                              imageBase64 = base64Encode(bytes);
                            });
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: const Text("Changer l'image"),
                      ),
                      if (imageBase64 != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Image.memory(
                            base64Decode(imageBase64!),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState?.validate() != true) return;

                          if (selectedCategorieId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Veuillez sélectionner une catégorie")),
                            );
                            return;
                          }

                          final updatedProduit = Produit(
                            id: produit.id,
                            nom: nomController.text,
                            marque: marqueController.text,
                            prixUnitaire:
                                double.tryParse(prixController.text) ?? 0,
                            imageBase64: imageBase64,
                            description: descriptionController.text,
                            categorieId: selectedCategorieId!,
                          );

                          try {
                            await ProduitService.updateProduit(
                                updatedProduit.id!, updatedProduit);
                            Navigator.pop(ctx);
                            _refreshProduits();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Produit modifié")),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Erreur : $e")),
                            );
                          }
                        },
                        child: const Text("Modifier"),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  late Future<bool> _isAdminFuture;

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Gestion des produits"),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadProduits,
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

    body: FutureBuilder<bool>(
      future: _isAdminFuture,
      builder: (context, adminSnapshot) {
        if (adminSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (adminSnapshot.hasError) {
          return Center(child: Text("Erreur : ${adminSnapshot.error}"));
        }
        final isAdmin = adminSnapshot.data ?? false;

        return FutureBuilder<List<Produit>>(
          future: _produitsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Erreur : ${snapshot.error}"));
            }

            final produits = snapshot.data ?? [];
            if (produits.isEmpty) {
              return const Center(child: Text("Aucun produit trouvé"));
            }

return RefreshIndicator(
  onRefresh: _refreshProduits,
  child: LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;

      int crossAxisCount;
      if (screenWidth >= 1200) {
        crossAxisCount = 4;
      } else if (screenWidth >= 900) {
        crossAxisCount = 3;
      } else if (screenWidth >= 600) {
        crossAxisCount = 2;
      } else {
        crossAxisCount = 1;
      }

      return GridView.builder(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.75, // <- réduit pour plus de hauteur verticale
        ),
        itemCount: produits.length,
        itemBuilder: (context, index) {
          final produit = produits[index];
          final isProduitOffert = produit.promotions?.any((p) =>
                  p.type == 'CADEAU' &&
                  p.produitOffertNom?.trim().toLowerCase() ==
                      produit.nom.trim().toLowerCase()) ??
              false;

          final imageWidget = produit.imageBase64 != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(produit.imageBase64!),
                    width: double.infinity,
                    height: 130,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  width: double.infinity,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 60,
                    color: Colors.grey,
                  ),
                );

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, cardConstraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: cardConstraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          imageWidget,
                          const SizedBox(height: 8),
                          Text(
                            produit.nom,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${produit.marque.isNotEmpty ? produit.marque : 'Marque inconnue'} · ${produit.categorieNom ?? ''}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (produit.promotions != null &&
                              produit.promotions!.isNotEmpty)
                            ...produit.promotions!.map((promo) {
                              if (promo.type == 'CADEAU') {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.card_giftcard,
                                              size: 16, color: Colors.green),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              "🎁 ${promo.nom} - ${promo.produitOffertNom ?? 'Inconnu'}",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (promo.quantiteCondition != null &&
                                          promo.quantiteCondition! > 0)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.list_alt,
                                                  size: 14,
                                                  color: Colors.blueGrey),
                                              const SizedBox(width: 6),
                                              Text(
                                                "Quantité condition : ${promo.quantiteCondition}",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.blueGrey,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (promo.quantiteOfferte != null &&
                                          promo.quantiteOfferte! > 0)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.card_giftcard,
                                                  size: 14,
                                                  color: Colors.green),
                                              const SizedBox(width: 6),
                                              Text(
                                                "Quantité offerte : ${promo.quantiteOfferte}",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              } else {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    "🏷️ ${promo.nom} - ${(promo.tauxReduction * 100).toStringAsFixed(1)}%",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }
                            }),
                          const SizedBox(height: 6),
                          Text(
                            isProduitOffert
                                ? "0.00 MAD"
                                : "${produit.prixUnitaire.toStringAsFixed(2)} MAD",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isAdmin)
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () =>
                                    _showActions(context, produit),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    },
  ),
);
   },
        );
      },
    ),
    floatingActionButton: FutureBuilder<bool>(
      future: _isAdminFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError ||
            !(snapshot.data ?? false)) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton(
          onPressed: () => _showAjoutProduitModal(context),
          child: const Icon(Icons.add),
        );
      },
    ),
  );
}


}
