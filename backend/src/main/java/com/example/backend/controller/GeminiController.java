
package com.example.backend.controller;

import com.example.backend.service.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.HttpServerErrorException;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/api/ia")
public class GeminiController {

    private final GeminiService geminiService;
    private final ProduitService produitService;
    private final ClientService clientService;
    private final CommandeService commandeService;
    private final AdminUtilisateurService adminUtilisateurService;
    private final Map<String, List<String>> historiqueParUtilisateur = new ConcurrentHashMap<>();
    private final DislogroupInfoService dislogroupInfoService;
    // Ajout des services manquants
    private final PromotionService promotionService;
    private final RouteService routeService;
    private final StockCamionService stockCamionService;
    private final VisiteService visiteService;

    // Configuration des tentatives
    private static final int MAX_RETRY_ATTEMPTS = 3;
    private static final long RETRY_DELAY_MS = 2000; // 2 secondes

    @Autowired
    public GeminiController(
            GeminiService geminiService,
            ProduitService produitService,
            ClientService clientService,
            CommandeService commandeService,
            AdminUtilisateurService adminUtilisateurService,
            DislogroupInfoService dislogroupInfoService,
            PromotionService promotionService,
            RouteService routeService,
            StockCamionService stockCamionService,
            VisiteService visiteService
    ) {
        this.geminiService = geminiService;
        this.produitService = produitService;
        this.clientService = clientService;
        this.commandeService = commandeService;
        this.adminUtilisateurService = adminUtilisateurService;
        this.dislogroupInfoService = dislogroupInfoService;
        this.promotionService = promotionService;
        this.routeService = routeService;
        this.stockCamionService = stockCamionService;
        this.visiteService = visiteService;
    }
    @PostMapping("/commande")
    public ResponseEntity<?> creerCommande(@RequestBody Map<String, String> payload) {
        String query = payload.get("query");
        if (query == null || query.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Le champ 'query' est obligatoire."));
        }

        try {
            String reponse = geminiService.traiterCommandeDepuisJsonGemini(query);
            return ResponseEntity.ok(Map.of("result", reponse));
        } catch (RuntimeException e) {
            // Gestion simple des erreurs métier
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            // Erreur serveur inattendue
            return ResponseEntity.status(500).body(Map.of("error", "Erreur interne serveur"));
        }
    }
    @PostMapping("/ask")
    public ResponseEntity<?> askQuestion(@RequestBody Map<String, String> payload) {
        String query = payload.get("query");
        if (query == null || query.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Missing 'query'"));
        }

        try {
            // Appeler la méthode pour remplacer les dates relatives dans la requête
            query = geminiService.remplacerDatesRelatives(query);

            // Récupérer l'utilisateur connecté
            String username = getCurrentUsername();
            if (username == null) username = "anonymous";

            // Initialiser historique s'il n'existe pas
            historiqueParUtilisateur.putIfAbsent(username, new ArrayList<>());
            List<String> historique = historiqueParUtilisateur.get(username);
            historique.add("User: " + query);

            // Si la question concerne Dislogroup, utiliser le service dédié
            if (query.toLowerCase().contains("dislogroup") || query.toLowerCase().contains("entreprise")) {
                String reponseDislogroup = dislogroupInfoService.repondreQuestionSurDislogroup(query);
                historique.add("Gemini: " + reponseDislogroup);
                return ResponseEntity.ok(Map.of("result", reponseDislogroup));
            }

            // Préparer le contexte
            String contexteComplet = prepareContext(historique);

            // Appeler Gemini avec retry logic
            String reponseIA = callGeminiWithRetry(query, contexteComplet);
            historique.add("Gemini: " + reponseIA);

            return ResponseEntity.ok(Map.of("result", reponseIA));

        } catch (HttpServerErrorException.ServiceUnavailable e) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(Map.of(
                            "error", "Le service IA est temporairement indisponible. Veuillez réessayer dans quelques instants.",
                            "code", "SERVICE_UNAVAILABLE",
                            "retry_after", "30"
                    ));
        } catch (HttpServerErrorException e) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body(Map.of(
                            "error", "Erreur du service IA: " + e.getMessage(),
                            "code", "IA_SERVICE_ERROR"
                    ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                            "error", "Erreur interne: " + e.getMessage(),
                            "code", "INTERNAL_ERROR"
                    ));
        }
    }

    private String callGeminiWithRetry(String query, String context) throws Exception {
        Exception lastException = null;

        for (int attempt = 1; attempt <= MAX_RETRY_ATTEMPTS; attempt++) {
            try {
                return geminiService.askGemini(query, context);
            } catch (HttpServerErrorException.ServiceUnavailable e) {
                lastException = e;
                if (attempt < MAX_RETRY_ATTEMPTS) {
                    try {
                        // Délai exponentiel: 2s, 4s, 8s
                        Thread.sleep(RETRY_DELAY_MS * attempt);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        throw new RuntimeException("Interruption pendant la pause de retry", ie);
                    }
                } else {
                    // Dernière tentative échouée
                    throw e;
                }
            } catch (Exception e) {
                // Pour les autres erreurs, on ne retry pas
                throw e;
            }
        }

        throw lastException;
    }

    private String prepareContext(List<String> historique) {
        String contexteProduits = produitService.genererContexteProduits();
        String contexteClients = clientService.genererContexteClients();
        String contexteCommandes = commandeService.genererContexteCommandes();
        String contexteUtilisateurs = adminUtilisateurService.genererContexteUtilisateurs();
        String contextePromotions = promotionService.genererContextePromotions();
        String contexteRoutes = routeService.genererContexteRoutes();
        String contexteStockCamions = stockCamionService.genererContexteStockCamions();
        String contexteVisites = visiteService.genererContexteVisites();

        String contexteHistorique = String.join("\n", historique);

        return String.join("\n\n",
                contexteProduits,
                contexteClients,
                contexteCommandes,
                contexteUtilisateurs,
                contextePromotions,
                contexteRoutes,
                contexteStockCamions,
                contexteVisites,
                "Historique de conversation :\n" + contexteHistorique
        );
    }

    private String getCurrentUsername() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.isAuthenticated()) {
            return auth.getName();
        }
        return null;
    }
}