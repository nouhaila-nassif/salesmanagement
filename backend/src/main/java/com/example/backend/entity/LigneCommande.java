package com.example.backend.entity;

import com.fasterxml.jackson.annotation.JsonIdentityInfo;
import com.fasterxml.jackson.annotation.ObjectIdGenerators;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "ligne_commande")
@JsonIdentityInfo(
        generator = ObjectIdGenerators.PropertyGenerator.class,
        property = "id"
)
public class LigneCommande {
    @Column(name = "produit_offert")
    private Boolean  produitOffert = false;

    public Boolean  isProduitOffert() {
        return produitOffert;
    }

    public void setProduitOffert(Boolean  produitOffert) {
        this.produitOffert = produitOffert;
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private Float prixUnitaire;
    public Float getPrixUnitaire() {
        return produit != null ? produit.getPrixUnitaire() : null;
    }


    public void setPrixUnitaire(Float prixUnitaire) {
        this.prixUnitaire = prixUnitaire;
    }

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "produit_id", nullable = false)
    private Produit produit;

    @Column(nullable = false)
    private int quantite;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "commande_id", nullable = false)
    private Commande commande;

    @ManyToMany
    @JoinTable(
            name = "lignecommande_promotion",
            joinColumns = @JoinColumn(name = "lignecommande_id"),
            inverseJoinColumns = @JoinColumn(name = "promotion_id")
    )
    private Set<Promotion> promotions = new HashSet<>();


    private BigDecimal prixUnitaireReduit; // à calculer ou setter dans service
    private BigDecimal reductionLigne; // idem

    // getters & setters
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

    public LigneCommande() {
    }

    public LigneCommande(Produit produit, int quantite, Commande commande) {
        this.produit = produit;
        this.quantite = quantite;
        this.commande = commande;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Produit getProduit() { return produit; }
    public void setProduit(Produit produit) { this.produit = produit; }

    public int getQuantite() { return quantite; }
    public void setQuantite(int quantite) { this.quantite = quantite; }

    public Commande getCommande() { return commande; }
    public void setCommande(Commande commande) { this.commande = commande; }

    public Set<Promotion> getPromotions() { return promotions; }
    public void setPromotions(Set<Promotion> promotions) { this.promotions = promotions; }

    public float getTotalLigne() {
        if (prixUnitaire != null) {
            return prixUnitaire * quantite;
        }
        return 0f;
    }


    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof LigneCommande)) return false;
        LigneCommande that = (LigneCommande) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return getClass().hashCode();
    }

    @Override
    public String toString() {
        return "LigneCommande{" +
                "id=" + id +
                ", produit=" + (produit != null ? produit.getId() : null) +
                ", quantite=" + quantite +
                ", commande=" + (commande != null ? commande.getId() : null) +
                '}';
    }
}
