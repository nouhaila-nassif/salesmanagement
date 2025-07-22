package com.example.backend.controller;

import com.example.backend.dto.PromotionDTO;
import com.example.backend.entity.*;
import com.example.backend.repository.CatégorieProduitRepository;
import com.example.backend.repository.ProduitRepository;
import com.example.backend.repository.PromotionRepository;
import com.example.backend.service.PromotionService;
import com.example.backend.service.UtilisateurService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/promotions")
public class PromotionController {

    @Autowired
    private UtilisateurService utilisateurService;
    @Autowired
    private CatégorieProduitRepository catégorieProduitRepository;
    @Autowired
    private PromotionService promotionService;
    @Autowired
    private ProduitRepository produitRepository;
@Autowired
    PromotionRepository promotionRepository;
    private Utilisateur getCurrentAdmin() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        Utilisateur utilisateur = utilisateurService.findByNomUtilisateur(username);
        if (!(utilisateur instanceof Administrateur)) {
            throw new RuntimeException("Accès refusé : seul un administrateur peut gérer les promotions.");
        }
        return utilisateur;
    }
    @PostMapping
    public ResponseEntity<?> create(@RequestBody PromotionDTO promotionDTO) {
        try {
            getCurrentAdmin(); // Sécurité : Admin uniquement

            Promotion promotion = new Promotion();

            // Champs simples
            promotion.setNom(promotionDTO.getNom());
            promotion.setType(promotionDTO.getType());
            promotion.setDateDebut(promotionDTO.getDateDebut());
            promotion.setDateFin(promotionDTO.getDateFin());
            promotion.setTauxReduction(promotionDTO.getTauxReduction());
            promotion.setSeuilQuantite(promotionDTO.getSeuilQuantite());
            promotion.setDiscountValue(promotionDTO.getDiscountValue());
            promotion.setQuantiteCondition(promotionDTO.getQuantiteCondition());
            promotion.setQuantiteOfferte(promotionDTO.getQuantiteOfferte());

            // Produits condition et offert (cadeau)
            if (promotionDTO.getProduitConditionNom() != null) {
                Produit produitCondition = produitRepository.findByNom(promotionDTO.getProduitConditionNom())
                        .orElseThrow(() -> new RuntimeException("Produit condition introuvable : " + promotionDTO.getProduitConditionNom()));
                promotion.setProduitCondition(produitCondition);
            }

            if (promotionDTO.getProduitOffertNom() != null) {
                Produit produitOffert = produitRepository.findByNom(promotionDTO.getProduitOffertNom())
                        .orElseThrow(() -> new RuntimeException("Produit offert introuvable : " + promotionDTO.getProduitOffertNom()));
                promotion.setProduitOffert(produitOffert);
            }

            // Catégorie ciblée (si applicable)
            if (promotionDTO.getCategorie() != null && promotionDTO.getCategorie().getId() != null) {
                CatégorieProduit cat = catégorieProduitRepository.findById(promotionDTO.getCategorie().getId())
                        .orElseThrow(() -> new RuntimeException("Catégorie introuvable"));
                promotion.setCategorie(cat);
            }

            // Produits liés (via liste d’IDs)
            if (promotionDTO.getProduitsIds() != null && !promotionDTO.getProduitsIds().isEmpty()) {
                Set<Produit> produits = promotionDTO.getProduitsIds().stream()
                        .map(id -> produitRepository.findById(id)
                                .orElseThrow(() -> new RuntimeException("Produit ID " + id + " introuvable")))
                        .collect(Collectors.toSet());
                promotion.setProduits(produits);
            } else {
                promotion.setProduits(new HashSet<>()); // éviter NullPointer
            }

            // 🔁 Appel du service métier
            Promotion saved = promotionService.createPromotion(promotion);

            return ResponseEntity.ok(new PromotionDTO(saved));

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erreur serveur : " + e.getMessage());
        }
    }

    @PostMapping("/apply")
    public ResponseEntity<String> appliquerPromotionSurCategorie(@RequestParam Long promotionId, @RequestParam Long categorieId) {
        try {
            promotionService.appliquerPromotionSurCategorie(promotionId, categorieId);
            return ResponseEntity.ok("Promotion appliquée avec succès.");
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }

    @GetMapping("/categorie/{categorieId}")
    public List<Promotion> getPromotionsParCategorie(@PathVariable Long categorieId) {
        return promotionService.getPromotionsParCategorie(categorieId);
    }
    @GetMapping
    public List<PromotionDTO> getAll() {
        List<Promotion> promotions = promotionService.getAllPromotions();
        return promotions.stream()
                .map(PromotionDTO::new)  // Convertit chaque Promotion en PromotionDTO via le constructeur
                .toList();
    }

    @GetMapping("/{id}")
    public Promotion getById(@PathVariable Long id) {
        return promotionService.getPromotionById(id);
    }


    @PutMapping("/{id}")
    public ResponseEntity<Promotion> update(@PathVariable Long id, @RequestBody Promotion promotion) {
        // Appelle ta méthode pour récupérer l'admin courant, par ex.
        getCurrentAdmin();

        try {
            Promotion updatedPromotion = promotionService.updatePromotion(id, promotion);
            return ResponseEntity.ok(updatedPromotion);
        } catch (RuntimeException ex) {
            // Gestion simple des erreurs : retourne 404 si la promo ou produit est introuvable
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        } catch (Exception ex) {
            // Gestion d'autres erreurs éventuelles
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }


    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        getCurrentAdmin(); // Vérifie que l'utilisateur est un admin
        promotionService.deletePromotion(id);
    }
}
