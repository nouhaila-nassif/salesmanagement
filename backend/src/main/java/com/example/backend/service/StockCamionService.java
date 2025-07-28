package com.example.backend.service;

import com.example.backend.entity.*;
import com.example.backend.repository.ProduitRepository;
import com.example.backend.repository.StockCamionRepository;
import com.example.backend.repository.UtilisateurRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class StockCamionService {
    @Autowired
    private
    UtilisateurService utilisateurService;
    @Autowired
    private UtilisateurRepository utilisateurRepository;
    private final StockCamionRepository stockCamionRepository;
    private final ProduitRepository produitRepository;

    public StockCamionService(StockCamionRepository stockCamionRepository,
                              ProduitRepository produitRepository,
                              UtilisateurService utilisateurService) {
        this.stockCamionRepository = stockCamionRepository;
        this.produitRepository = produitRepository;
        this.utilisateurService = utilisateurService;
    }

    // ✅ Voir son propre stock camion (seulement pour VendeurDirect)
    public StockCamion voirSonStock() {
        Utilisateur user = utilisateurService.getUtilisateurActuel();

        if (!(user instanceof VendeurDirect)) {
            throw new AccessDeniedException("Accès interdit : seul un Vendeur Direct peut voir son stock.");
        }

        return stockCamionRepository.findByChauffeur((VendeurDirect) user)
                .orElseThrow(() -> new RuntimeException("Aucun stock trouvé pour ce vendeur."));
    }

    public StockCamion creerStockPourVendeur(VendeurDirect vendeur) {
        // Vérifier s'il existe déjà un stock pour ce vendeur
        Optional<StockCamion> existant = stockCamionRepository.findByChauffeur(vendeur);
        if (existant.isPresent()) {
            return existant.get();
        }

        StockCamion nouveauStock = new StockCamion();
        nouveauStock.setChauffeur(vendeur);
        // Initialise la map des niveaux de stock vide
        nouveauStock.setNiveauxStock(new HashMap<>());
        return stockCamionRepository.save(nouveauStock);
    }
    private StockCamion getStockCamionCourant() {
        Utilisateur user = utilisateurService.getUtilisateurActuel();

        if (!(user instanceof VendeurDirect)) {
            throw new RuntimeException("Utilisateur courant n'est pas un vendeur direct.");
        }

        return stockCamionRepository.findByChauffeur((VendeurDirect) user)
                .orElseThrow(() -> new RuntimeException("Aucun stock trouvé pour ce vendeur."));
    }

    @Transactional
    public void incrementerStock(Long produitId, int quantite) {
        // Récupérer le stock du camion (ici on suppose qu'on travaille avec le vendeur connecté,
        // sinon tu dois passer le vendeur en paramètre pour cibler le bon stock)

        StockCamion stockCamion = getStockCamionCourant(); // méthode à adapter selon contexte

        if (stockCamion == null) {
            throw new RuntimeException("Stock camion introuvable.");
        }

        Map<Produit, Integer> niveauxStock = stockCamion.getNiveauxStock();

        // Trouver le produit dans la map
        Produit produitCle = null;
        for (Produit p : niveauxStock.keySet()) {
            if (p.getId().equals(produitId)) {
                produitCle = p;
                break;
            }
        }

        if (produitCle == null) {
            throw new RuntimeException("Produit non trouvé dans le stock.");
        }

        int stockActuel = niveauxStock.get(produitCle);
        int stockMisAJour = stockActuel + quantite;

        niveauxStock.put(produitCle, stockMisAJour);

        // Sauvegarder le stock mis à jour
        stockCamion.setNiveauxStock(niveauxStock);
        stockCamionRepository.save(stockCamion);

        System.out.println("Stock incrémenté pour produit " + produitCle.getNom() + " : +" + quantite + " (total : " + stockMisAJour + ")");
    }
    // ✅ Charger du stock dans camion (VendeurDirect ou ResponsableUnité via validation)
    public void chargerStock(Long produitId, int quantite, Long stockId) {
        Utilisateur user = utilisateurService.getUtilisateurActuel();
        boolean isVendeur = user instanceof VendeurDirect;
        boolean isResponsable = user instanceof ResponsableUnite;

        if (!isVendeur && !isResponsable) {
            throw new AccessDeniedException("Seuls les vendeurs ou responsables peuvent charger du stock.");
        }

        Produit produit = produitRepository.findById(produitId)
                .orElseThrow(() -> new RuntimeException("Produit introuvable"));

        StockCamion stock = stockCamionRepository.findById(stockId)
                .orElseThrow(() -> new RuntimeException("Stock introuvable"));

        if (isVendeur && !stock.getChauffeur().equals(user)) {
            throw new AccessDeniedException("Vous ne pouvez charger que votre propre stock.");
        }

        stock.charger(produit, quantite);
        stockCamionRepository.save(stock);
    }

    public void supprimerStock(Long stockId) {
        Utilisateur user = utilisateurService.getUtilisateurActuel();

        boolean isAdmin = user instanceof Administrateur;
        boolean isSuperviseur = user instanceof Superviseur;
        boolean isResponsable = user instanceof ResponsableUnite;
        boolean isVendeur = user instanceof VendeurDirect;

        StockCamion stock = stockCamionRepository.findById(stockId)
                .orElseThrow(() -> new RuntimeException("Stock introuvable."));

        // Autorisation :
        if (!(isAdmin || isSuperviseur || isResponsable || (isVendeur && stock.getChauffeur().equals(user)))) {
            throw new AccessDeniedException("Accès interdit : vous ne pouvez pas supprimer ce stock.");
        }

        stockCamionRepository.delete(stock);
    }
    public void supprimerProduitDuStock(Long stockId, Long produitId) {
        Utilisateur user = utilisateurService.getUtilisateurActuel();

        boolean isAdmin = user instanceof Administrateur;
        boolean isSuperviseur = user instanceof Superviseur;
        boolean isResponsable = user instanceof ResponsableUnite;
        boolean isVendeur = user instanceof VendeurDirect;

        StockCamion stock = stockCamionRepository.findById(stockId)
                .orElseThrow(() -> new RuntimeException("Stock introuvable."));

        // Autorisation :
        if (!(isAdmin || isSuperviseur || isResponsable || (isVendeur && stock.getChauffeur().equals(user)))) {
            throw new AccessDeniedException("Accès interdit : vous ne pouvez pas modifier ce stock.");
        }

        // Trouver le produit dans le stock
        Produit produit = produitRepository.findById(produitId)
                .orElseThrow(() -> new RuntimeException("Produit introuvable."));

        // Supposons que niveauxStock est une Map<Produit, Integer>
        Map<Produit, Integer> niveauxStock = stock.getNiveauxStock();

        if (!niveauxStock.containsKey(produit)) {
            throw new RuntimeException("Le produit n'existe pas dans ce stock.");
        }

        // Supprimer le produit de la Map (ou mettre quantité à zéro)
        niveauxStock.remove(produit);

        // Sauvegarder la modification
        stockCamionRepository.save(stock);
    }
    private Utilisateur getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();

        return utilisateurRepository.findByNomUtilisateur(username)
                .orElseThrow(() -> new UsernameNotFoundException("Utilisateur non trouvé : " + username));
    }
    public String genererContexteStockCamions() {
        Utilisateur utilisateur = getCurrentUser(); // récupère l'utilisateur connecté
        List<StockCamion> stocks;

        switch (utilisateur.getRole()) {
            case "ADMIN":
                stocks = voirTousLesStocks();
                break;

            case "SUPERVISEUR":
                List<Utilisateur> vendeurs = utilisateurRepository.findAll().stream()
                        .filter(u -> (u instanceof VendeurDirect || u instanceof PreVendeur))
                        .filter(u -> {
                            if (u instanceof VendeurDirect vd) {
                                return vd.getSuperviseur() != null && vd.getSuperviseur().getId().equals(utilisateur.getId());
                            } else if (u instanceof PreVendeur pv) {
                                return pv.getSuperviseur() != null && pv.getSuperviseur().getId().equals(utilisateur.getId());
                            }
                            return false;
                        })
                        .toList();

                List<Long> idsDesVendeurs = vendeurs.stream()
                        .map(Utilisateur::getId)
                        .toList();

                stocks = voirTousLesStocks().stream()
                        .filter(stock -> stock.getChauffeur() != null &&
                                idsDesVendeurs.contains(stock.getChauffeur().getId()))
                        .toList();
                break;

            case "VENDEURDIRECT":
            case "PREVENDEUR":
                try {
                    StockCamion monStock = voirSonStock(); // Peut jeter une exception si non vendeur
                    stocks = monStock != null ? List.of(monStock) : List.of();
                } catch (Exception e) {
                    stocks = List.of(); // Ne pas bloquer le chatbot, même si aucun stock trouvé
                }
                break;

            default:
                stocks = List.of(); // Pour éviter une exception et permettre au bot de continuer
        }

        if (stocks.isEmpty()) {
            return "Aucun stock camion trouvé pour votre profil.";
        }

        StringBuilder contexte = new StringBuilder("État actuel des stocks camions :\n");

        for (StockCamion stock : stocks) {
            Long stockId = stock.getId();
            String chauffeurNom = (stock.getChauffeur() != null)
                    ? stock.getChauffeur().getNomUtilisateur()
                    : "Chauffeur inconnu";

            Map<Produit, Integer> niveaux = stock.getNiveauxStock();
            int totalProduits = niveaux.values().stream().mapToInt(Integer::intValue).sum();

            String produitsDetails = niveaux.isEmpty()
                    ? "Aucun produit"
                    : niveaux.entrySet().stream()
                    .map(e -> e.getKey().getNom() + " x" + e.getValue())
                    .collect(Collectors.joining(", "));

            contexte.append("- [Stock ID: ").append(stockId).append("] ")
                    .append("Chauffeur : ").append(chauffeurNom)
                    .append(" | Produits (").append(totalProduits).append(") : ")
                    .append(produitsDetails)
                    .append("\n");
        }

        return contexte.toString();
    }
    // ✅ Déduire du stock après vente (automatique pour VendeurDirect)

    public void deduireStock(Long produitId, int quantite) {
        Utilisateur user = utilisateurService.getUtilisateurActuel();

        if (!(user instanceof VendeurDirect)) {
            throw new AccessDeniedException("Seuls les vendeurs peuvent déduire automatiquement du stock.");
        }

        StockCamion stock = stockCamionRepository.findByChauffeur((VendeurDirect) user)
                .orElseThrow(() -> new RuntimeException("Aucun stock trouvé."));

        Produit produit = produitRepository.findById(produitId)
                .orElseThrow(() -> new RuntimeException("Produit introuvable"));

        stock.déduire(produit, quantite);
        stockCamionRepository.save(stock);
    }

    // ✅ Visualiser le stock d’un autre vendeur (pour Admin, Superviseur, ResponsableUnité)
    public List<StockCamion> voirTousLesStocks() {
        Utilisateur user = utilisateurService.getUtilisateurActuel();

        if (!(user instanceof Administrateur || user instanceof Superviseur || user instanceof ResponsableUnite)) {
            throw new AccessDeniedException("Accès interdit.");
        }

        return stockCamionRepository.findAll();  // Ou créer une méthode spécifique pour filtrer uniquement les vendeurs directs
    }


    // ✅ Modifier stock manuellement
    public void modifierManuellement(Long stockId, Long produitId, int nouvelleQuantite) {
        Utilisateur user = utilisateurService.getUtilisateurActuel();

        boolean isAdmin = user instanceof Administrateur;
        boolean isSuperviseur = user instanceof Superviseur;
        boolean isResponsable = user instanceof ResponsableUnite;
        boolean isVendeur = user instanceof VendeurDirect;

        // Charger le stock
        StockCamion stock = stockCamionRepository.findById(stockId)
                .orElseThrow(() -> new RuntimeException("Stock non trouvé."));

        // Vérifier les droits d'accès
        if (!(isAdmin || isSuperviseur || isResponsable || (isVendeur && stock.getChauffeur().equals(user)))) {
            throw new AccessDeniedException("Accès interdit : vous n'avez pas le droit de modifier ce stock.");
        }

        // Charger le produit
        Produit produit = produitRepository.findById(produitId)
                .orElseThrow(() -> new RuntimeException("Produit non trouvé."));

        // Modifier la quantité
        stock.getNiveauxStock().put(produit, nouvelleQuantite);

        // Sauvegarder
        stockCamionRepository.save(stock);
    }

}
