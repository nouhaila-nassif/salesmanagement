package com.example.backend.dto;

public class ProduitStockDto {
    private Long produitId;
    private String nom;
    private String description;
    private String marque;
    private Double prixUnitaire;
    private String imageBase64;
    private int quantite;

    // Constructeur sans argument (nécessaire pour Jackson)
    public ProduitStockDto() {
    }

    // Constructeur avec tous les champs
    public ProduitStockDto(Long produitId, String nom, String description, String marque,
                           Double prixUnitaire, String imageBase64, int quantite) {
        this.produitId = produitId;
        this.nom = nom;
        this.description = description;
        this.marque = marque;
        this.prixUnitaire = prixUnitaire;
        this.imageBase64 = imageBase64;
        this.quantite = quantite;
    }

    // Getters et setters

    public Long getProduitId() {
        return produitId;
    }

    public void setProduitId(Long produitId) {
        this.produitId = produitId;
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

    public Double getPrixUnitaire() {
        return prixUnitaire;
    }

    public void setPrixUnitaire(Double prixUnitaire) {
        this.prixUnitaire = prixUnitaire;
    }

    public String getImageBase64() {
        return imageBase64;
    }

    public void setImageBase64(String imageBase64) {
        this.imageBase64 = imageBase64;
    }

    public int getQuantite() {
        return quantite;
    }

    public void setQuantite(int quantite) {
        this.quantite = quantite;
    }
}
