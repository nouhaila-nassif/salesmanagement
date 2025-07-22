import 'package:flutter/material.dart';
import '../../models/Categorie.dart';
import '../../models/produit.dart';
import '../../models/promotion.dart';
import '../../services/categorie_service.dart';
import '../../services/produit_service.dart';
import '../../services/promotion_service.dart';
import '../../widgets/navigation_bar.dart';

class ListePromotionsPage extends StatefulWidget {
  final String userRole;
  final String userName;
  final VoidCallback onLogout;
  final Function(String route, {Map<String, dynamic>? arguments}) onNavigate;

  const ListePromotionsPage({
    Key? key,
    required this.userRole,
    required this.userName,
    required this.onLogout,
    required this.onNavigate,
  }) : super(key: key);

  @override
  State<ListePromotionsPage> createState() => _ListePromotionsPageState();
}

class _ListePromotionsPageState extends State<ListePromotionsPage> {
  late Future<List<Promotion>> _promotionsFuture;
  late Future<List<Produit>> _produitsFuture;
  List<Categorie> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadPromotions();
    _loadCategories();
    _loadProduits();
  }

  void _loadProduits() {
    setState(() {
      _produitsFuture = ProduitService.getAllProduits();
    });
  }

  void _loadCategories() async {
    final categories = await CategorieService.getAllCategories();
    setState(() => _categories = categories);
  }

  void _loadPromotions() {
    _promotionsFuture = PromotionService.getAllPromotions();
  }

  void _supprimerPromotion(int id) async {
    await PromotionService.deletePromotion(id);
    setState(() => _loadPromotions());
  }

  Future<void> _ouvrirFormulaire({Promotion? promo}) async {
    final formKey = GlobalKey<FormState>();
    const List<String> allowedTypes = ['TPR', 'LPR', 'CADEAU', 'REMISE'];
    String nom = promo?.nom ?? '';
    String type = promo?.type ?? allowedTypes.first;
    double taux =
        promo?.tauxReduction != null ? promo!.tauxReduction * 100 : 0.0;
    int? seuilQuantite = promo?.seuilQuantite;
    String? produitConditionNom = promo?.produitConditionNom;
    int? quantiteCondition = promo?.quantiteCondition;
    String? produitOffertNom = promo?.produitOffertNom;
    int? quantiteOfferte = promo?.quantiteOfferte;
    DateTime? debut = promo?.dateDebut;
    DateTime? fin = promo?.dateFin;
    int? selectedCategorieId = promo?.categorie?.id;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text(promo == null ? "Nouvelle promotion" : "Modifier promotion"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder<List<Produit>>(
              future: _produitsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Text('Erreur chargement produits: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Aucun produit disponible');
                }
                final produits = snapshot.data!;
                return Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: type,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: allowedTypes.map((t) {
                            String label;
                            switch (t) {
                              case 'TPR':
                                label = 'Tarif promotionnel réduit';
                                break;
                              case 'LPR':
                                label = 'Lot promotionnel réduit';
                                break;
                              case 'CADEAU':
                                label = 'Produit offert';
                                break;
                              case 'REMISE':
                                label = 'Réduction';
                                break;
                              default:
                                label = t;
                            }
                            return DropdownMenuItem(
                                value: t, child: Text(label));
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => type = val ?? allowedTypes.first),
                          validator: (val) =>
                              val == null || val.isEmpty ? "Requis" : null,
                        ),
                        TextFormField(
                          initialValue: nom,
                          decoration: const InputDecoration(
                              labelText: 'Nom de la promotion'),
                          onChanged: (val) => nom = val,
                          validator: (val) =>
                              val == null || val.isEmpty ? "Nom requis" : null,
                        ),
                        if (type == 'TPR' || type == 'REMISE')
                          TextFormField(
                            initialValue: taux.toStringAsFixed(2),
                            decoration: const InputDecoration(
                                labelText: 'Taux de réduction (%)'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (val) =>
                                taux = double.tryParse(val) ?? 0.0,
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Requis";
                              final parsed = double.tryParse(val);
                              if (parsed == null || parsed < 0 || parsed > 100)
                                return "Doit être entre 0 et 100";
                              return null;
                            },
                          ),
                        if (type == 'LPR')
                          TextFormField(
                            initialValue: taux.toStringAsFixed(2),
                            decoration: const InputDecoration(
                                labelText: 'Taux de réduction (%)'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (val) =>
                                taux = double.tryParse(val) ?? 0.0,
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Requis";
                              final parsed = double.tryParse(val);
                              if (parsed == null || parsed < 0 || parsed > 100)
                                return "Doit être entre 0 et 100";
                              return null;
                            },
                          ),
                        if (type == 'REMISE')
                          TextFormField(
                            initialValue: seuilQuantite?.toString(),
                            decoration: const InputDecoration(
                                labelText: 'Seuil de quantité'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) =>
                                seuilQuantite = int.tryParse(val),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Requis' : null,
                          ),
                        if (type == 'CADEAU') ...[
                          DropdownButtonFormField<String>(
                            value: produitConditionNom,
                            decoration: const InputDecoration(
                                labelText: 'Produit condition'),
                            items: produits.map((prod) {
                              return DropdownMenuItem(
                                value: prod.nom,
                                child: Text(prod.nom),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => produitConditionNom = val),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Requis' : null,
                          ),
                          TextFormField(
                            initialValue: quantiteCondition?.toString(),
                            decoration: const InputDecoration(
                                labelText: 'Quantité condition'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) =>
                                quantiteCondition = int.tryParse(val),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Requis' : null,
                          ),
                          DropdownButtonFormField<String>(
                            value: produitOffertNom,
                            decoration: const InputDecoration(
                                labelText: 'Produit offert'),
                            items: produits.map((prod) {
                              return DropdownMenuItem(
                                value: prod.nom,
                                child: Text(prod.nom),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => produitOffertNom = val),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Requis' : null,
                          ),
                          TextFormField(
                            initialValue: quantiteOfferte?.toString(),
                            decoration: const InputDecoration(
                                labelText: 'Quantité offerte'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) =>
                                quantiteOfferte = int.tryParse(val),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Requis' : null,
                          ),
                        ],
                        if (type != 'CADEAU')
                          DropdownButtonFormField<int>(
                            value: selectedCategorieId,
                            decoration:
                                const InputDecoration(labelText: 'Catégorie'),
                            items: _categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat.id,
                                child: Text(cat.nom),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => selectedCategorieId = val),
                            validator: (val) =>
                                val == null ? 'Catégorie requise' : null,
                          ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: debut ?? DateTime.now(),
                              firstDate: DateTime(2023),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => debut = picked);
                          },
                          child: Text(debut == null
                              ? "Choisir date début"
                              : "Début: ${debut!.toLocal().toString().split(' ')[0]}"),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: fin ?? DateTime.now(),
                              firstDate: DateTime(2023),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => fin = picked);
                          },
                          child: Text(fin == null
                              ? "Choisir date fin"
                              : "Fin: ${fin!.toLocal().toString().split(' ')[0]}"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate() &&
                  debut != null &&
                  fin != null) {
                final categorie = (type == 'CADEAU')
                    ? null
                    : _categories
                        .firstWhere((c) => c.id == selectedCategorieId);
                final nouvellePromo = Promotion(
                  id: promo?.id,
                  nom: nom,
                  type: type,
                  tauxReduction:
                      (type == 'TPR' || type == 'REMISE' || type == 'LPR')
                          ? (taux / 100)
                          : 0.0,
                  seuilQuantite: (type == 'REMISE') ? seuilQuantite : null,
                  produitConditionNom:
                      (type == 'CADEAU') ? produitConditionNom : null,
                  quantiteCondition:
                      (type == 'CADEAU') ? quantiteCondition : null,
                  produitOffertNom:
                      (type == 'CADEAU') ? produitOffertNom : null,
                  quantiteOfferte: (type == 'CADEAU') ? quantiteOfferte : null,
                  dateDebut: debut!,
                  dateFin: fin!,
                  categorie: categorie,
                );
                try {
                  if (promo == null) {
                    await PromotionService.createPromotion(nouvellePromo);
                  } else {
                    await PromotionService.updatePromotion(
                        promo.id!, nouvellePromo);
                  }
                  Navigator.pop(context);
                  setState(() => _loadPromotions());
                } catch (e) {
                  setState(() {
                    errorMessage = e.toString().replaceFirst('Exception: ', '');
                  });
                }
              }
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Promotions"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPromotions,
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

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ouvrirFormulaire(),
        icon: const Icon(Icons.add),
        label: const Text("Ajouter"),
      ),
      body: FutureBuilder<List<Promotion>>(
        future: _promotionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Erreur de chargement"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune promotion trouvée"));
          }
          final promotions = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 1;
              if (constraints.maxWidth >= 1200) {
                crossAxisCount = 3;
              } else if (constraints.maxWidth >= 700) {
                crossAxisCount = 2;
              }
              return GridView.count(
                crossAxisCount: crossAxisCount,
                padding: const EdgeInsets.all(12),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3 / 2,
                children: promotions.map((promo) {
                  final bool isExpired = promo.dateFin.isBefore(DateTime.now());
                  return Opacity(
                    opacity: isExpired ? 0.5 : 1.0,
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  promo.type == 'CADEAU'
                                      ? Icons.card_giftcard
                                      : promo.type == 'REMISE'
                                          ? Icons.percent
                                          : Icons.local_offer,
                                  color: isExpired
                                      ? Colors.grey
                                      : Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    promo.nom ?? "Sans nom",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isExpired
                                          ? Colors.grey
                                          : Colors.black,
                                      decoration: isExpired
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () =>
                                      _ouvrirFormulaire(promo: promo),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _supprimerPromotion(promo.id!),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              promo.type +
                                  (promo.type != 'CADEAU'
                                      ? " - " +
                                          (promo.categorie?.nom ??
                                              'Sans catégorie')
                                      : ''),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isExpired ? Colors.grey : Colors.black,
                                decoration: isExpired
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (promo.type == 'TPR' || promo.type == 'REMISE')
                              Text(
                                "Taux réduction : ${(promo.tauxReduction * 100).toStringAsFixed(2)}%",
                                style: TextStyle(
                                  color: isExpired ? Colors.grey : Colors.black,
                                  decoration: isExpired
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            if (promo.type == 'LPR')
                              Text(
                                "Taux réduction : ${(promo.tauxReduction * 100).toStringAsFixed(2)}%",
                                style: TextStyle(
                                  color: isExpired ? Colors.grey : Colors.black,
                                  decoration: isExpired
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            if (promo.type == 'REMISE')
                              Text(
                                "Seuil quantité : ${promo.seuilQuantite ?? 'N/A'}",
                                style: TextStyle(
                                  color: isExpired ? Colors.grey : Colors.black,
                                  decoration: isExpired
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            if (promo.type == 'CADEAU') ...[
                              Text(
                                "Produit condition : ${promo.produitConditionNom ?? 'N/A'} x${promo.quantiteCondition ?? 'N/A'}",
                                style: TextStyle(
                                  color: isExpired ? Colors.grey : Colors.black,
                                  decoration: isExpired
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              Text(
                                "Produit offert : ${promo.produitOffertNom ?? 'N/A'} x${promo.quantiteOfferte ?? 'N/A'}",
                                style: TextStyle(
                                  color: isExpired ? Colors.grey : Colors.black,
                                  decoration: isExpired
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              "Début : ${promo.dateDebut.toLocal().toString().split(' ')[0]}",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            Text(
                              "Fin : ${promo.dateFin.toLocal().toString().split(' ')[0]}",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
