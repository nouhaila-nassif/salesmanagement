package com.example.backend.service;
import com.example.backend.entity.*;
import com.example.backend.repository.ClientRepository;
import com.example.backend.repository.ProduitRepository;
import com.example.backend.repository.UtilisateurRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.HttpHeaders;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class GeminiService {

    @Value("${gemini.api.key}")
    private String apiKey;
    @Autowired
    private UtilisateurRepository utilisateurRepository;
    @Value("${gemini.api.url}")
    private String apiUrl;
    @Autowired
    private ClientRepository clientRepository;
    private final RestTemplate restTemplate = new RestTemplate();
    @Autowired
    UtilisateurService  utilisateurService;
    @Autowired
    private CommandeService commandeService;
    @Autowired
    private ProduitRepository produitRepository;


    private Map<String, Integer> extraireProduits(String query) {
        Map<String, Integer> produits = new HashMap<>();
        if (query == null || query.isBlank()) return produits;

        // Extraire uniquement la partie après "avec les produits"
        String[] split = query.toLowerCase().split("avec les produits", 2);
        if (split.length < 2) return produits;

        String produitsBruts = split[1].trim();

        // Séparer chaque item par virgule ou "et"
        String[] items = produitsBruts.split("\\s*(,|et)\\s*");

        for (String item : items) {
            item = item.trim();

            // ✅ Nouveau format : "NomProduit*Quantité"
            if (item.contains("*")) {
                String[] parts = item.split("\\*");
                if (parts.length == 2) {
                    String nomProduit = parts[0].trim();
                    try {
                        int quantite = Integer.parseInt(parts[1].trim());
                        produits.put(nomProduit, quantite);
                        continue;
                    } catch (NumberFormatException e) {
                        // ignorer et continuer avec d'autres formats
                    }
                }
            }

            // 🧠 Sinon, tenter les anciens formats : "3 shampoing", "shampoing 3"
            String regex1 = "(\\d+)\\s+([a-zA-Z\\s]+)";
            String regex2 = "([a-zA-Z\\s]+)\\s+(\\d+)";
            Matcher matcher = Pattern.compile(regex1).matcher(item);
            if (matcher.find()) {
                produits.put(matcher.group(2).trim(), Integer.parseInt(matcher.group(1).trim()));
                continue;
            }

            matcher = Pattern.compile(regex2).matcher(item);
            if (matcher.find()) {
                produits.put(matcher.group(1).trim(), Integer.parseInt(matcher.group(2).trim()));
            }
        }

        return produits;
    }
    public String corrigerCommandeAvecGemini(String texteBrut) {
        String nomsClients = clientRepository.findAll()
                .stream()
                .map(Client::getNom)
                .collect(Collectors.joining(", "));

        String nomsProduits = produitRepository.findAll()
                .stream()
                .map(Produit::getNom)
                .collect(Collectors.joining(", "));

        String prompt = """
Tu es un assistant qui corrige et structure les commandes commerciales.

Voici la liste des clients valides : [%s]
Voici la liste des produits valides : [%s]

À partir du texte ci-dessous (même mal écrit), fais les 2 choses suivantes :
1. Corrige les fautes (orthographe, accents, grammaire)
2. Identifie clairement :
    - Le nom exact du client (existant dans la liste)
    - Les produits (noms + quantités) même si mal orthographiés

Retourne le résultat dans ce format JSON strict :

{
  "client": "Nom Client",
  "produits": [
    { "nom": "Produit A", "quantite": 3 },
    { "nom": "Produit B", "quantite": 2 }
  ]
}

Commande reçue : "%s"
""".formatted(nomsClients, nomsProduits, texteBrut);

        return askGemini(prompt, "");
    }
    private String extraireClient(String query) {
        if (query == null || query.isBlank()) {
            throw new RuntimeException("Commande vide.");
        }

        // Regex pour capturer le client après "commande à" ou "commande pour"
        String regex = "(?i)commande\\s+(?:à|a|pour)\\s+([\\w\\s\\-\\.]+?)(?=\\s+avec|\\s+produits|:|$)";

        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(query);

        if (matcher.find()) {
            String client = matcher.group(1).trim();
            if (!client.isEmpty()) {
                return client;
            }
        }

        throw new RuntimeException("Impossible d'extraire le nom du client.");
    }

    private Utilisateur getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || authentication.getPrincipal().equals("anonymousUser")) {
            return null;  // Pas d’utilisateur connecté
        }
        String username = authentication.getName();
        return utilisateurService.findByNomUtilisateur(username);
    }
    private boolean isValidJSON(String json) {
        try {
            final ObjectMapper mapper = new ObjectMapper();
            mapper.readTree(json);
            return true;
        } catch (IOException e) {
            return false;
        }
    }

    public String traiterCommandeDepuisJsonGemini(String query) {
        try {
            String jsonResponse = corrigerCommandeAvecGemini(query);
            System.out.println("Réponse brute Gemini : " + jsonResponse);

            if (!isValidJSON(jsonResponse)) {
                // La réponse n'est pas JSON, on la retourne comme message d'erreur
                return "{\"result\": \"❌ Erreur dans la réponse Gemini : réponse non JSON valide.\"}";
            }

            ObjectMapper objectMapper = new ObjectMapper();
            JsonNode root = objectMapper.readTree(jsonResponse);

            // Le reste du traitement comme avant...
            String clientName = root.get("client").asText();
            Client client = clientRepository.findByNomIgnoreCaseAndTrimmed(clientName)
                    .orElseThrow(() -> new RuntimeException("❌ Client introuvable : " + clientName));

            List<LigneCommande> lignes = new ArrayList<>();
            Commande commande = new Commande();
            commande.setClient(client);
            commande.setDateCreation(LocalDate.now());
            commande.setDateLivraison(LocalDate.now().plusDays(3));

            for (JsonNode produitNode : root.get("produits")) {
                String nomProduit = produitNode.get("nom").asText();
                int quantite = produitNode.get("quantite").asInt();

                Produit produit = produitRepository.findByNomIgnoreCaseAndTrimmed(nomProduit)
                        .orElseThrow(() -> new RuntimeException("❌ Produit introuvable : " + nomProduit));

                LigneCommande ligne = new LigneCommande();
                ligne.setProduit(produit);
                ligne.setQuantite(quantite);
                ligne.setPrixUnitaire(produit.getPrixUnitaire());
                ligne.setCommande(commande);
                lignes.add(ligne);
            }

            commande.setLignes(lignes);

            Utilisateur vendeur = getCurrentUser();
            if (vendeur == null) {
                throw new RuntimeException("❌ Aucun utilisateur connecté.");
            }

            Commande saved = commandeService.creerCommande(commande, vendeur);

            return "✅ Commande créée pour **" + client.getNom() + "** avec ID: " + saved.getId();

        } catch (Exception e) {
            return "{\"result\": \"❌ Erreur lors du traitement : " + e.getMessage().replace("\"", "\\\"") + "\"}";
        }
    }

    public String remplacerDatesRelatives(String query) {
        LocalDate aujourdHui = LocalDate.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");

        if (query.toLowerCase().contains("demain")) {
            String dateDemain = aujourdHui.plusDays(1).format(formatter);
            query = query.replaceAll("(?i)demain", dateDemain);
        }

        if (query.toLowerCase().contains("aujourd'hui")) {
            String dateAujourdhui = aujourdHui.format(formatter);
            query = query.replaceAll("(?i)aujourd'hui", dateAujourdhui);
        }

        if (query.toLowerCase().contains("hier")) {
            String dateHier = aujourdHui.minusDays(1).format(formatter);
            query = query.replaceAll("(?i)hier", dateHier);
        }

        return query;
    }
    public String askGemini(String query, String context) {
        try {
            String prompt = "Context:\n" + context + "\n\nQuestion:\n" + query + "\n\nAnswer using only the provided context.";

            Map<String, Object> requestBody = new HashMap<>();
            List<Map<String, Object>> parts = List.of(Map.of("text", prompt));
            requestBody.put("contents", List.of(Map.of("parts", parts)));

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("x-goog-api-key", apiKey);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);

            ResponseEntity<Map> response = restTemplate.postForEntity(apiUrl, request, Map.class);

            List<Map> candidates = (List<Map>) response.getBody().get("candidates");
            Map content = (Map) candidates.get(0).get("content");
            List<Map> partsResponse = (List<Map>) content.get("parts");

            return partsResponse.get(0).get("text").toString();

        } catch (Exception e) {
            e.printStackTrace();
            return "Erreur avec Gemini";
        }
    }

}

