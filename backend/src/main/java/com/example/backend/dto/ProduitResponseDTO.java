package com.example.backend.dto;

import java.util.List;

public class ProduitResponseDTO {
    private Long id;
    private String nom;
    private String description;
    private String marque;
    private Float  prixUnitaire;
    private String imageUrl;
    private String imageBase64;
    private Long categorieId;
    private List<PromotionDTO> promotions; // ✅ Nouveau champ

    public List<PromotionDTO> getPromotions() {
        return promotions;
    }

    public void setPromotions(List<PromotionDTO> promotions) {
        this.promotions = promotions;
    }

    private String categorieNom; // 👈 nom de la catégorie

    public Long getId() {
        return id;
    }

    public Long getCategorieId() {
        return categorieId;
    }

    public void setCategorieId(Long categorieId) {
        this.categorieId = categorieId;
    }

    public void setId(Long id) {
        this.id = id;
    }

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

    public Float  getPrixUnitaire() {
        return prixUnitaire;
    }

    public void setPrixUnitaire(Float  prixUnitaire) {
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

    public String getCategorieNom() {
        return categorieNom;
    }

    public void setCategorieNom(String categorieNom) {
        this.categorieNom = categorieNom;
    }
// Getters & Setters
}
