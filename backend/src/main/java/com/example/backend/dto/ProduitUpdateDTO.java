package com.example.backend.dto;

public class ProduitUpdateDTO {
    private String nom;
    private String description;
    private String marque;
    private Float prixUnitaire;
    private String imageUrl;
    private String imageBase64;
    private Long categorieId;
    private Long approuveParId;  // Only need ID for relationships

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

    public Float getPrixUnitaire() {
        return prixUnitaire;
    }

    public void setPrixUnitaire(Float prixUnitaire) {
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

    public Long getApprouveParId() {
        return approuveParId;
    }

    public void setApprouveParId(Long approuveParId) {
        this.approuveParId = approuveParId;
    }
// Getters and setters
}
