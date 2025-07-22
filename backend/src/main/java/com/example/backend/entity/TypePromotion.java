package com.example.backend.entity;
public enum TypePromotion {
    TPR("Tarif promotionnel réduit"),
    LPR("Lot promotionnel réduit"),
    CADEAU("Produit offert"),
    REMISE("Réduction");

    private final String libelle;

    TypePromotion(String libelle) {
        this.libelle = libelle;
    }

    public String getLibelle() {
        return libelle;
    }
}
