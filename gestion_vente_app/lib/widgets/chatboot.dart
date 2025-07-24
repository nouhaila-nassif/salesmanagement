import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/commande_service.dart';
import '../services/produit_service.dart';
import '../services/client_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../services/promotion_service.dart';
import '../services/route_service.dart';
import '../services/utilisateur_service.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final String _apiKey = "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";

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(_ChatMessage(
      sender: "Bot",
      message: """# 🤖 Bienvenue dans votre assistant commercial !

Je peux vous aider avec :
- 🛒 **Produits** : recherche, prix, disponibilité
- 👤 **Clients** : informations, historique
- 📦 **Commandes** : détails, statuts, montants
- 🗺️ **Routes** : vendeurs, clients assignés
- 🎁 **Promotions** : offres actives, conditions
- 👥 **Utilisateurs** : rôles, contacts

**Exemple de questions :**
- "Qui est le client X ?"
- "Quels sont les produits de la commande 123 ?"
- "Email du client Y ?"
- "Promotions actives ?"

Posez votre question ! 👇""",
      timestamp: DateTime.now(),
    ));
  }

@override
Widget build(BuildContext context) {
  final primaryColor = Theme.of(context).primaryColor;

  return Scaffold(
    appBar: AppBar(
      title: const Text("Assistant Commercial IA"),
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    body: Column(
      children: [
        // Messages area
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, primaryColor);
              },
            ),
          ),
        ),

        // Loading indicator
        if (_isLoading)
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  "L'assistant réfléchit...",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

        // Input area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "Posez votre question...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onSubmitted: _handleUserMessage,
                  onChanged: (value) => setState(() {}),
                  enabled: !_isLoading,
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                onPressed: _isLoading ? null : () => _handleUserMessage(_controller.text),
                backgroundColor: _isLoading ? Colors.grey : primaryColor,
                mini: true,
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildMessageBubble(_ChatMessage msg, Color primaryColor) {
  final isUser = msg.sender == "Vous";

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
        ],

        Expanded(
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Sender name and timestamp
              Row(
                mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Text(
                      "Assistant",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _formatTimestamp(msg.timestamp),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (isUser) ...[
                    const SizedBox(width: 8),
                    const Text(
                      "Vous",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),

              // Message bubble
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUser ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                    bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isUser
                    ? Text(
                        msg.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      )
                    : MarkdownBody(
                        data: msg.message,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            color: Colors.black87,
                          ),
                          h1: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            height: 1.2,
                          ),
                          h2: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                          h3: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            height: 1.2,
                          ),
                          listBullet: TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                          ),
                          code: TextStyle(
                            backgroundColor: Colors.grey[100],
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          blockquote: TextStyle(
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border(
                              left: BorderSide(
                                color: Colors.grey[400]!,
                                width: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),

        if (isUser) ...[
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ],
    ),
  );
}

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return "Maintenant";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}min";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h";
    } else {
      return "${timestamp.day}/${timestamp.month}";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleUserMessage(String message) async {
    if (message.trim().isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(
        sender: "Vous",
        message: message.trim(),
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Récupération des données
      final produits = await ProduitService.getAllProduits();
      final clients = await ClientService.getAllClients();
      final promotions = await PromotionService.getAllPromotions();
      final routes = await RouteService.getAllRoutes();
      final commandes = await CommandeService.getCommandes();
      final utilisateurs = await UtilisateurService.getAllUtilisateurs();

      // Formatage des données
      final infosProduits = produits.map((p) {
        return "ID: ${p.id} | ${p.nom} | Catégorie: ${p.categorieNom} | Description: ${p.description ?? "Pas de description"} | Prix: ${p.prixUnitaire} DH | Stock disponible";
      }).toList();

      final infosClients = clients.map((c) {
        return "ID: ${c.id} | ${c.nom} | Type: ${c.type} | Adresse: ${c.adresse ?? "Non spécifiée"} | Téléphone: ${c.telephone ?? "Non spécifié"} | Email: ${c.email ?? "Email non spécifié"}";
      }).toList();

      final infosPromotions = promotions.map((promo) {
        return """ID: ${promo.id} | ${promo.nom} (${promo.type}) | Réduction: ${promo.tauxReduction * 100}% | Période: ${promo.dateDebut.toIso8601String().split('T')[0]} → ${promo.dateFin.toIso8601String().split('T')[0]} | Condition: ${promo.produitConditionNom ?? "Aucune"} (${promo.quantiteCondition ?? "N/A"}) | Offre: ${promo.produitOffertNom ?? "Aucune"} (${promo.quantiteOfferte ?? "N/A"})""";
      }).toList();

      final infosRoutes = routes.map((r) {
        final vendeurs = r.vendeurs.map((v) => v.nomUtilisateur).join(", ");
        final clientsRoute = r.clients.map((c) => c.nom).join(", ");
        return "ID: ${r.id} | ${r.nom} | Vendeurs: ${vendeurs.isNotEmpty ? vendeurs : "Aucun"} | Clients: ${clientsRoute.isNotEmpty ? clientsRoute : "Aucun"}";
      }).toList();

      final infosCommandes = commandes.map((cmd) {
        final lignesDescription = cmd.lignes.map((ligne) {
          return "  - ${ligne.produit.nom} × ${ligne.quantite} = ${ligne.produit.prixUnitaire * ligne.quantite} DH${ligne.produitOffert ? " (OFFERT)" : ""}";
        }).join("\n");

        return """ID: ${cmd.id} | Client: ${cmd.clientNom} | Créée: ${cmd.dateCreation} | Livraison: ${cmd.dateLivraison} | Total: ${cmd.montantTotal} DH | Avant remise: ${cmd.montantTotalAvantRemise} DH | Réduction: ${cmd.montantReduction} DH | Statut: ${cmd.statut} | Promotions: ${cmd.promotionsAppliquees.map((p) => p.nom).join(", ")}
Produits:
$lignesDescription""";
      }).toList();

      final infosUtilisateurs = utilisateurs.map((u) {
        return "ID: ${u.id} | ${u.nomUtilisateur} | Rôle: ${u.role} | Téléphone: ${u.telephone ?? "Non spécifié"} | Email: ${u.email ?? "Non spécifié"} | Superviseur: ${u.superviseurNom ?? "Aucun"}";
      }).toList();

      // Envoi à l'IA
      final botResponse = await _sendToIA(
        message,
        infosProduits,
        infosClients,
        infosCommandes,
        infosRoutes,
        infosPromotions,
        infosUtilisateurs,
      );

      setState(() {
        _messages.add(_ChatMessage(
          sender: "Bot",
          message: botResponse,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          sender: "Bot",
          message: "❌ **Erreur lors de la récupération des données**\n\n```\n$e\n```",
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }

    _controller.clear();
    _scrollToBottom();
  }

  Future<String> _sendToIA(
    String userMessage,
    List<String> produits,
    List<String> clients,
    List<String> commandes,
    List<String> routes,
    List<String> promotions,
    List<String> utilisateurs,
  ) async {
    if (_apiKey.isEmpty) {
      return "❌ **Configuration manquante**\n\nClé API non définie.";
    }

    // Analyse du message pour détecter le type de question
    final messageAnalysis = _analyzeMessage(userMessage);
    
    final systemPrompt = """Tu es un assistant commercial expert qui répond **exclusivement en Markdown structuré**.

## 📊 BASE DE DONNÉES DISPONIBLE

### 🛒 PRODUITS (${produits.length})
${produits.take(50).join('\n')}
${produits.length > 50 ? '\n... et ${produits.length - 50} autres produits' : ''}

### 👤 CLIENTS (${clients.length})
${clients.take(50).join('\n')}
${clients.length > 50 ? '\n... et ${clients.length - 50} autres clients' : ''}

### 📦 COMMANDES (${commandes.length})
${commandes.take(20).join('\n---\n')}
${commandes.length > 20 ? '\n... et ${commandes.length - 20} autres commandes' : ''}

### 🗺️ ROUTES (${routes.length})
${routes.join('\n')}

### 🎁 PROMOTIONS (${promotions.length})
${promotions.join('\n')}

### 👥 UTILISATEURS (${utilisateurs.length})
${utilisateurs.join('\n')}

## 🎯 RÈGLES DE RÉPONSE STRICTES

### 1. **RÉPONSE PRÉCISE ET CIBLÉE**
- Réponds **uniquement** à ce qui est demandé
- Si question spécifique → réponse spécifique
- Si question générale → vue d'ensemble structurée

### 2. **GESTION DES ÉLÉMENTS NON TROUVÉS**
- Si élément non trouvé → message clair avec ❌
- Propose des alternatives similaires avec ⚠️
- **JAMAIS** d'invention de données

### 3. **STRUCTURE MARKDOWN OBLIGATOIRE**
- Utilise # ## ### pour les titres
- Utilise - ou * pour les listes
- Utilise **gras** pour les éléments importants
- Utilise `code` pour les IDs/références
- Utilise > pour les citations/notes importantes
- Utilise des emojis appropriés (🛒 📦 👤 🎁 etc.)

### 4. **TYPES DE QUESTIONS COURANTES**

**Question d'identité** ("Qui est X?", "Infos sur Y")
→ Toutes les infos disponibles, bien structurées

**Question spécifique** ("Email de X", "Prix de Y")
→ Réponse directe et précise

**Question de recherche** ("Tous les produits de catégorie X")
→ Liste filtrée et organisée

**Question de comparaison** ("Différence entre X et Y")
→ Tableau comparatif si possible

**Question de statistiques** ("Combien de...", "Total des...")
→ Chiffres avec contexte

### 5. **CORRECTION AUTOMATIQUE**
- Corrige les fautes d'orthographe
- Interprète les abréviations communes
- Gère les synonymes (commande = cmd, promotion = promo)

### 6. **RÉPONSES D'ERREUR**
Si aucune donnée trouvée :
```
❌ **Aucune information trouvée**

La recherche pour "${messageAnalysis['query']}" n'a donné aucun résultat dans la base de données.

**Suggestions :**
- Vérifiez l'orthographe
- Utilisez des termes plus généraux
- Consultez la liste complète avec "tous les [produits/clients/commandes]"
```

### 7. **LANGUE ET STYLE**
- Réponds **toujours en français**
- Ton professionnel mais accessible
- Utilise des emojis avec modération
- Privilégie la clarté à l'exhaustivité

---

**Question de l'utilisateur :** $userMessage

**Analyse détectée :** ${messageAnalysis['type']} - ${messageAnalysis['intent']}

Réponds maintenant selon ces règles.""";

    try {
      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "model": "mistralai/mistral-7b-instruct",
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": userMessage},
          ],
          "temperature": 0.3,
          "max_tokens": 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final message = data["choices"]?[0]?["message"]?["content"];
        return message?.trim() ?? "❌ **Aucune réponse générée**\n\nL'IA n'a pas pu traiter votre demande.";
      } else {
        return "❌ **Erreur de communication**\n\n**Code :** ${response.statusCode}\n**Message :** ${response.reasonPhrase}\n\n```\n${response.body}\n```";
      }
    } catch (e) {
      return "❌ **Erreur technique**\n\n```\n$e\n```\n\n> Vérifiez votre connexion internet et réessayez.";
    }
  }

  Map<String, String> _analyzeMessage(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Détection du type de question
    if (lowerMessage.contains(RegExp(r'\b(qui est|infos? sur|détails? de)\b'))) {
      return {'type': 'identity', 'intent': 'Information complète sur une entité'};
    }
    
    if (lowerMessage.contains(RegExp(r'\b(email|téléphone|adresse|contact)\b'))) {
      return {'type': 'contact', 'intent': 'Information de contact spécifique'};
    }
    
    if (lowerMessage.contains(RegExp(r'\b(prix|coût|tarif|montant)\b'))) {
      return {'type': 'price', 'intent': 'Information tarifaire'};
    }
    
    if (lowerMessage.contains(RegExp(r'\b(commande|cmd|commandes)\b'))) {
      return {'type': 'order', 'intent': 'Information sur les commandes'};
    }
    
    if (lowerMessage.contains(RegExp(r'\b(promotion|promo|réduction|offre)\b'))) {
      return {'type': 'promotion', 'intent': 'Information sur les promotions'};
    }
    
    if (lowerMessage.contains(RegExp(r'\b(tous les|toutes les|liste)\b'))) {
      return {'type': 'list', 'intent': 'Listage d\'éléments'};
    }
    
    if (lowerMessage.contains(RegExp(r'\b(combien|nombre|total|statistique)\b'))) {
      return {'type': 'statistics', 'intent': 'Demande statistique'};
    }
    
    return {'type': 'general', 'intent': 'Question générale', 'query': message};
  }
}

class _ChatMessage {
  final String sender;
  final String message;
  final DateTime timestamp;
  
  _ChatMessage({
    required this.sender,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}