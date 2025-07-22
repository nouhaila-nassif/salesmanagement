package com.example.backend.dto;

import java.math.BigDecimal;

public class LigneCommandeDTO {
    private Long id;
    private int quantite;
    private Long produitId;
    private ProductDTO produit;
    private boolean produitOffert; // true si c'est un cadeau, false sinon

    public boolean isProduitOffert() {
        return produitOffert;
    }

    public void setProduitOffert(boolean produitOffert) {
        this.produitOffert = produitOffert;
    }

    private BigDecimal prixUnitaireOriginal;  // prix avant promo
    private BigDecimal prixUnitaireReduit;   // prix après promo
    private BigDecimal reductionLigne;       // montant de la réduction appliquée

    public LigneCommandeDTO() {
    }

    public LigneCommandeDTO(Long id, int quantite, Long produitId, ProductDTO produit,
                            BigDecimal prixUnitaireOriginal, BigDecimal prixUnitaireReduit, BigDecimal reductionLigne) {
        this.id = id;
        this.quantite = quantite;
        this.produitId = produitId;
        this.produit = produit;
        this.prixUnitaireOriginal = prixUnitaireOriginal;
        this.prixUnitaireReduit = prixUnitaireReduit;
        this.reductionLigne = reductionLigne;
    }

    // Getters et setters
    public Long getId() {
        return id;
    }
    public void setId(Long id) {
        this.id = id;
    }

    public int getQuantite() {
        return quantite;
    }
    public void setQuantite(int quantite) {
        this.quantite = quantite;
    }

    public Long getProduitId() {
        return produitId;
    }
    public void setProduitId(Long produitId) {
        this.produitId = produitId;
    }

    public ProductDTO getProduit() {
        return produit;
    }
    public void setProduit(ProductDTO produit) {
        this.produit = produit;
    }

    public BigDecimal getPrixUnitaireOriginal() {
        return prixUnitaireOriginal;
    }
    public void setPrixUnitaireOriginal(BigDecimal prixUnitaireOriginal) {
        this.prixUnitaireOriginal = prixUnitaireOriginal;
    }

    public BigDecimal getPrixUnitaireReduit() {
        return prixUnitaireReduit;
    }
    public void setPrixUnitaireReduit(BigDecimal prixUnitaireReduit) {
        this.prixUnitaireReduit = prixUnitaireReduit;
    }

    public BigDecimal getReductionLigne() {
        return reductionLigne;
    }
    public void setReductionLigne(BigDecimal reductionLigne) {
        this.reductionLigne = reductionLigne;
    }
}
