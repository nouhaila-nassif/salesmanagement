package com.example.backend.service;

import com.example.backend.entity.*;
import com.example.backend.repository.CatégorieProduitRepository;
import com.example.backend.repository.ProduitRepository;
import com.example.backend.repository.PromotionRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.temporal.ChronoUnit;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
@Service
public class PromotionService {
    @Autowired
    CatégorieProduitRepository catProdRepo;
    private final PromotionRepository promotionRepository;
    @Autowired
    private
    ProduitRepository produitRepository;

    public PromotionService(PromotionRepository promotionRepository) {
        this.promotionRepository = promotionRepository;
    }

    public List<Promotion> getPromotionsByProduitId(Long produitId) {
        return promotionRepository.findByProduitId(produitId);
    }

    public void appliquerPromotionSurCategorie(Long promotionId, Long categorieId) {
        Promotion promotion = promotionRepository.findById(promotionId)
                .orElseThrow(() -> new RuntimeException("Promotion introuvable avec id : " + promotionId));

        CatégorieProduit categorie = catProdRepo.findById(categorieId)
                .orElseThrow(() -> new RuntimeException("Catégorie introuvable avec id : " + categorieId));

        // Lier la promotion à la catégorie
        promotion.setCategorie(categorie);

        // Sauvegarder la promotion mise à jour
        promotionRepository.save(promotion);
    }

    /**
     * Retourne toutes les promotions liées à une catégorie donnée
     */
    public List<Promotion> getPromotionsParCategorie(Long categorieId) {
        CatégorieProduit categorie = catProdRepo.findById(categorieId)
                .orElseThrow(() -> new RuntimeException("Catégorie introuvable avec id : " + categorieId));

        return promotionRepository.findByCategorie(categorie);
    }

    @Transactional
    public Promotion createPromotion(Promotion promotion) {
        if (promotion.getDateDebut() == null || promotion.getDateFin() == null) {
            throw new IllegalArgumentException("Les dates de début et fin doivent être renseignées.");
        }

        if (promotion.getDateFin().isBefore(promotion.getDateDebut())) {
            throw new IllegalArgumentException("La date de fin ne peut pas être antérieure à la date de début.");
        }

        long dureeJours = ChronoUnit.DAYS.between(promotion.getDateDebut(), promotion.getDateFin()) + 1;

        if (promotion.getType() == null) {
            throw new IllegalArgumentException("Le type de promotion doit être défini.");
        }

        switch (promotion.getType()) {
            case TPR:
                if (promotion.getTauxReduction() == null) {
                    throw new IllegalArgumentException("La promotion TPR nécessite un taux de réduction.");
                }
                if (dureeJours > 14) {
                    throw new IllegalArgumentException("La durée maximale d'une promotion TPR est de 14 jours.");
                }
                break;

            case LPR:
                if (promotion.getTauxReduction() == null) {
                    throw new IllegalArgumentException("La promotion TPR nécessite un taux de réduction.");
                }
                if (dureeJours < 30) {
                    throw new IllegalArgumentException("La durée minimale d'une promotion LPR est de 30 jours.");
                }
                break;

            case CADEAU:
                if (promotion.getProduitCondition() == null ||
                        promotion.getProduitOffert() == null ||
                        promotion.getQuantiteCondition() == null ||
                        promotion.getQuantiteOfferte() == null) {
                    throw new IllegalArgumentException("La promotion CADEAU nécessite un produit condition, un produit offert, et des quantités.");
                }

                // Ajout des produits condition et offert à la liste de produits de la promo
                promotion.getProduits().add(promotion.getProduitCondition());
                promotion.getProduits().add(promotion.getProduitOffert());
                break;

            case REMISE:
                if (promotion.getTauxReduction() == null || promotion.getSeuilQuantite() == null) {
                    throw new IllegalArgumentException("La promotion REMISE nécessite un taux de réduction et un seuil de quantité.");
                }
                break;

            default:
                throw new IllegalArgumentException("Type de promotion non reconnu : " + promotion.getType());
        }

        // 💡 Étape CRUCIALE : découper la sauvegarde en 2 temps
        Set<Produit> produitsLies = promotion.getProduits(); // on garde en mémoire
        promotion.setProduits(new HashSet<>()); // éviter erreur NULL ID

        // 1. Sauvegarde sans produits
        Promotion saved = promotionRepository.save(promotion);

        // 2. On réassigne les produits à la promotion maintenant qu’elle a un ID
        if (produitsLies != null && !produitsLies.isEmpty()) {
            saved.setProduits(produitsLies);
            saved = promotionRepository.save(saved); // ceci insère dans promotion_produit avec un ID valide
        }

        return saved;
    }

    public List<Promotion> getAllPromotions() {
        return promotionRepository.findAll();
    }

    public Promotion getPromotionById(Long id) {
        return promotionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Promotion non trouvée"));
    }

    public String genererContextePromotions() {
        List<Promotion> promotions = promotionRepository.findAll();

        if (promotions.isEmpty()) return "Aucune promotion en cours.";

        StringBuilder contexte = new StringBuilder("Liste des promotions en cours :\n");

        for (Promotion promo : promotions) {
            String nom = promo.getNom() != null ? promo.getNom() : "Nom inconnu";
            String type = promo.getType() != null ? promo.getType().name() : "Type inconnu";
            String dateDebut = promo.getDateDebut() != null ? promo.getDateDebut().toString() : "Date début inconnue";
            String dateFin = promo.getDateFin() != null ? promo.getDateFin().toString() : "Date fin inconnue";
            String taux = promo.getTauxReduction() != null ? promo.getTauxReduction() + "%" : "Pas de réduction";
            String categorie = (promo.getCategorie() != null) ? promo.getCategorie().getNom() : "Sans catégorie";

            // ✅ Produits liés à la promotion
            String produits = promo.getProduits() != null && !promo.getProduits().isEmpty()
                    ? promo.getProduits().stream()
                    .map(Produit::getNom)
                    .reduce((p1, p2) -> p1 + ", " + p2)
                    .orElse("Aucun produit")
                    : "Aucun produit";

            // ✅ Détails spécifiques pour le type CADEAU
            String detailsCadeau = "";
            if (promo.getType() == TypePromotion.CADEAU) {
                String produitCond = promo.getProduitCondition() != null ? promo.getProduitCondition().getNom() : "Inconnu";
                String qteCond = promo.getQuantiteCondition() != null ? promo.getQuantiteCondition().toString() : "?";
                String produitOff = promo.getProduitOffert() != null ? promo.getProduitOffert().getNom() : "Inconnu";
                String qteOff = promo.getQuantiteOfferte() != null ? promo.getQuantiteOfferte().toString() : "?";
                detailsCadeau = " | 🎁 Offre : Achetez " + qteCond + " " + produitCond + " => Recevez " + qteOff + " " + produitOff;
            }

            contexte.append("- [ID: ").append(promo.getId())
                    .append("] ").append(nom)
                    .append(" | Type : ").append(type)
                    .append(" | Catégorie : ").append(categorie)
                    .append(" | Dates : ").append(dateDebut).append(" → ").append(dateFin)
                    .append(" | Taux : ").append(taux)
                    .append(" | Produits : ").append(produits)
                    .append(detailsCadeau)
                    .append("\n");
        }

        return contexte.toString();
    }


    public Promotion updatePromotion(Long id, Promotion newData) {
        Promotion existing = getPromotionById(id);
        if (newData.getType() == TypePromotion.CADEAU) {
            if (newData.getProduitConditionNom() != null) {
                Produit produitCondition = produitRepository.findByNom(newData.getProduitConditionNom())
                        .orElseThrow(() -> new RuntimeException("Produit condition introuvable : " + newData.getProduitConditionNom()));
                existing.setProduitCondition(produitCondition);
                existing.setQuantiteCondition(newData.getQuantiteCondition());
            }

            if (newData.getProduitOffertNom() != null) {
                Produit produitOffert = produitRepository.findByNom(newData.getProduitOffertNom())
                        .orElseThrow(() -> new RuntimeException("Produit offert introuvable : " + newData.getProduitOffertNom()));
                existing.setProduitOffert(produitOffert);
                existing.setQuantiteOfferte(newData.getQuantiteOfferte());
            }
        }

        if (newData.getNom() != null) existing.setNom(newData.getNom());
        if (newData.getType() != null) existing.setType(newData.getType());
        if (newData.getDateDebut() != null) existing.setDateDebut(newData.getDateDebut());
        if (newData.getDateFin() != null) existing.setDateFin(newData.getDateFin());
        if (newData.getTauxReduction() != null) existing.setTauxReduction(newData.getTauxReduction());
        if (newData.getDiscountValue() != null) existing.setDiscountValue(newData.getDiscountValue());
        if (newData.getSeuilQuantite() != null) existing.setSeuilQuantite(newData.getSeuilQuantite());

        if (newData.getCategorie() != null && newData.getCategorie().getId() != null) {
            CatégorieProduit categorie = catProdRepo.findById(newData.getCategorie().getId())
                    .orElseThrow(() -> new RuntimeException("Catégorie introuvable avec id : " + newData.getCategorie().getId()));
            existing.setCategorie(categorie);
        }

        if (newData.getType() == TypePromotion.CADEAU) {
            if (newData.getProduitCondition() != null && newData.getProduitCondition().getNom() != null) {
                Produit produitCondition = produitRepository.findByNom(newData.getProduitCondition().getNom())
                        .orElseThrow(() -> new RuntimeException("Produit condition introuvable avec nom : " + newData.getProduitCondition().getNom()));
                existing.setProduitCondition(produitCondition);
                existing.setQuantiteCondition(newData.getQuantiteCondition());
            }
            if (newData.getProduitOffert() != null && newData.getProduitOffert().getNom() != null) {
                Produit produitOffert = produitRepository.findByNom(newData.getProduitOffert().getNom())
                        .orElseThrow(() -> new RuntimeException("Produit offert introuvable avec nom : " + newData.getProduitOffert().getNom()));
                existing.setProduitOffert(produitOffert);
                existing.setQuantiteOfferte(newData.getQuantiteOfferte());
            }
        } else {
            // Nettoyer seulement si le type a changé
            existing.setProduitCondition(null);
            existing.setQuantiteCondition(null);
            existing.setProduitOffert(null);
            existing.setQuantiteOfferte(null);
        }

        return promotionRepository.save(existing);
    }



    public void deletePromotion(Long id) {
        promotionRepository.deleteById(id);
    }
}
