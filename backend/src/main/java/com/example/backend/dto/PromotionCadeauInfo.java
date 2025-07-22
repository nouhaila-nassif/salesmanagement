package com.example.backend.dto;


import java.util.Objects;

public class PromotionCadeauInfo {
    private Long promotionId;
    private String produitOffertNom;
    private Integer quantite;

    // Propriétés optionnelles pour les conditions (si nécessaire)
    private String produitConditionNom;
    private Integer quantiteCondition;

    // Constructeurs
    public PromotionCadeauInfo() {}

    public PromotionCadeauInfo(Long promotionId, String produitOffertNom, Integer quantite) {
        this.promotionId = promotionId;
        this.produitOffertNom = produitOffertNom;
        this.quantite = quantite;
    }

    // Getters et Setters
    public Long getPromotionId() {
        return promotionId;
    }

    public void setPromotionId(Long promotionId) {
        this.promotionId = promotionId;
    }

    public String getProduitOffertNom() {
        return produitOffertNom;
    }

    public void setProduitOffertNom(String produitOffertNom) {
        this.produitOffertNom = produitOffertNom;
    }

    public Integer getQuantite() {
        return quantite;
    }

    public void setQuantite(Integer quantite) {
        this.quantite = quantite;
    }

    public String getProduitConditionNom() {
        return produitConditionNom;
    }

    public void setProduitConditionNom(String produitConditionNom) {
        this.produitConditionNom = produitConditionNom;
    }

    public Integer getQuantiteCondition() {
        return quantiteCondition;
    }

    public void setQuantiteCondition(Integer quantiteCondition) {
        this.quantiteCondition = quantiteCondition;
    }

    // equals et hashCode pour le fonctionnement correct du Set
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        PromotionCadeauInfo that = (PromotionCadeauInfo) o;
        return Objects.equals(promotionId, that.promotionId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(promotionId);
    }

    @Override
    public String toString() {
        return "PromotionCadeauInfo{" +
                "promotionId=" + promotionId +
                ", produitOffertNom='" + produitOffertNom + '\'' +
                ", quantite=" + quantite +
                '}';
    }
}