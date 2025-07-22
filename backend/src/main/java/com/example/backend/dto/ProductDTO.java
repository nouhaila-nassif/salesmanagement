package com.example.backend.dto;

import com.example.backend.entity.Produit;
import com.example.backend.entity.Promotion;

import java.time.LocalDate;
import java.util.Optional;

public class ProductDTO {
    private String nom;
    private String description;
    private String marque;
    private Double prixUnitaire;
    private String imageUrl;
    private String imageBase64;
    private Long categorieId;

    private PromotionDTO promotion; // Unique promotion (pas une liste)

    public ProductDTO() {}

    public ProductDTO(Produit produit) {
        this.nom = produit.getNom();
        this.description = produit.getDescription();
        this.marque = produit.getMarque();
        this.prixUnitaire = produit.getPrixUnitaire() != null
                ? produit.getPrixUnitaire().doubleValue()
                : null;
        this.imageUrl = produit.getImageUrl();
        this.imageBase64 = produit.getImageBase64();
        this.categorieId = produit.getCategorie() != null
                ? produit.getCategorie().getId()
                : null;

        LocalDate today = LocalDate.now();

        if (produit.getPromotions() != null && !produit.getPromotions().isEmpty()) {
            Optional<Promotion> promoActive = produit.getPromotions().stream()
                    .filter(promo ->
                            (promo.getDateDebut() == null || !promo.getDateDebut().isAfter(today)) &&
                                    (promo.getDateFin() == null || !promo.getDateFin().isBefore(today))
                    )
                    .findFirst();

            promoActive.ifPresent(promo -> this.promotion = new PromotionDTO(promo));
        }
    }

    // Getters & Setters

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getMarque() {
        return marque;
    }

    public void setMarque(String marque) {
        this.marque = marque;
    }

    public Double getPrixUnitaire() {
        return prixUnitaire;
    }

    public void setPrixUnitaire(Double prixUnitaire) {
        this.prixUnitaire = prixUnitaire;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public String getImageBase64() {
        return imageBase64;
    }

    public void setImageBase64(String imageBase64) {
        this.imageBase64 = imageBase64;
    }

    public Long getCategorieId() {
        return categorieId;
    }

    public void setCategorieId(Long categorieId) {
        this.categorieId = categorieId;
    }

    public PromotionDTO getPromotion() {
        return promotion;
    }

    public void setPromotion(PromotionDTO promotion) {
        this.promotion = promotion;
    }
}
