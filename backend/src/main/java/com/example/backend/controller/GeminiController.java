
package com.example.backend.controller;

import com.example.backend.service.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
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
    AudioTranscriptionController audioTranscriptionController;
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

    @PostMapping(
            value = "/ask-json",
            consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<?> askQuestionJson(@RequestBody Map<String, String> payload) {
        String query = payload.get("query");
        if (query == null || query.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Missing 'query'"));
        }

        try {
            query = geminiService.remplacerDatesRelatives(query);

            String username = getCurrentUsername();
            if (username == null) username = "anonymous";

            historiqueParUtilisateur.putIfAbsent(username, new ArrayList<>());
            List<String> historique = historiqueParUtilisateur.get(username);
            historique.add("User: " + query);

            if (query.toLowerCase().contains("dislogroup") || query.toLowerCase().contains("entreprise")) {
                String reponseDislogroup = dislogroupInfoService.repondreQuestionSurDislogroup(query);
                historique.add("Gemini: " + reponseDislogroup);
                return ResponseEntity.ok(Map.of("result", reponseDislogroup));
            }

            String contexteComplet = prepareContext(historique);
            String reponseIA = callGeminiWithRetry(query, contexteComplet);
            historique.add("Gemini: " + reponseIA);

            return ResponseEntity.ok(Map.of("result", reponseIA));

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping(
            value = "/ask-multipart",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<?> askQuestionMultipart(
            @RequestPart(value = "query", required = false) String query,
            @RequestPart(value = "audioFile", required = false) MultipartFile audioFile) {

        try {
            String transcription = null;

            if ((query == null || query.isBlank()) && (audioFile == null || audioFile.isEmpty())) {
                return ResponseEntity.badRequest().body(Map.of("error", "Missing 'query' or 'audioFile'"));
            }

            // 🎤 Étape 1 : Transcrire l'audio s'il existe
            if (audioFile != null && !audioFile.isEmpty()) {
                File tempFile = File.createTempFile("upload_", ".wav");
                audioFile.transferTo(tempFile);

                transcription = audioTranscriptionController.executerWhisper(
                        tempFile.getAbsolutePath(),
                        System.getProperty("java.io.tmpdir")
                );

                tempFile.delete();

                if (transcription == null || transcription.isBlank()) {
                    return ResponseEntity.badRequest().body(Map.of("error", "Transcription vide"));
                }

                System.out.println("[API /ask-multipart] ✅ Transcription : " + transcription);

                // ⚠️ Utiliser la transcription comme query si vide
                if (query == null || query.isBlank()) {
                    query = transcription;
                }
            }

            // 🔁 Traitement IA avec Gemini
            query = geminiService.remplacerDatesRelatives(query);

            String username = getCurrentUsername();
            if (username == null) username = "anonymous";

            historiqueParUtilisateur.putIfAbsent(username, new ArrayList<>());
            List<String> historique = historiqueParUtilisateur.get(username);
            historique.add("User: " + query);

            String reponseIA;
            if (query.toLowerCase().contains("dislogroup") || query.toLowerCase().contains("entreprise")) {
                reponseIA = dislogroupInfoService.repondreQuestionSurDislogroup(query);
            } else {
                String contexteComplet = prepareContext(historique);
                reponseIA = callGeminiWithRetry(query, contexteComplet);
            }

            historique.add("Gemini: " + reponseIA);

            // 📦 Retourner transcription + réponse
            return ResponseEntity.ok(Map.of(
                    "transcription", transcription,
                    "result", reponseIA


            ));

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
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