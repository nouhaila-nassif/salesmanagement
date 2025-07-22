package com.example.backend.entity;

import com.fasterxml.jackson.annotation.*;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.Set;

@JsonIdentityInfo(
        generator = ObjectIdGenerators.PropertyGenerator.class,
        property = "id"
)
@Entity
@JsonIgnoreProperties({"lignesCommandes"})
public class Promotion {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;

    @Column(nullable = false)
    private String nom;

    @Enumerated(EnumType.STRING)
    private TypePromotion type; // TPR, LPR, GIFT, REBATE_VOLUME

    private LocalDate dateDebut;
    private LocalDate dateFin;

    public Long getId() {
        return id;
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

    public TypePromotion getType() {
        return type;
    }

    public void setType(TypePromotion type) {
        this.type = type;
    }

    public LocalDate getDateDebut() {
        return dateDebut;
    }

    public void setDateDebut(LocalDate dateDebut) {
        this.dateDebut = dateDebut;
    }

    public LocalDate getDateFin() {
        return dateFin;
    }

    public void setDateFin(LocalDate dateFin) {
        this.dateFin = dateFin;
    }

    public BigDecimal getDiscountValue() {
        return discountValue;
    }

    public void setDiscountValue(BigDecimal discountValue) {
        this.discountValue = discountValue;
    }

    public BigDecimal getTauxReduction() {
        return tauxReduction;
    }
    private String produitConditionNom;
    private String produitOffertNom;

    public String getProduitConditionNom() {
        return produitConditionNom;
    }

    public void setProduitConditionNom(String produitConditionNom) {
        this.produitConditionNom = produitConditionNom;
    }

    public String getProduitOffertNom() {
        return produitOffertNom;
    }

    public void setProduitOffertNom(String produitOffertNom) {
        this.produitOffertNom = produitOffertNom;
    }

    public void setTauxReduction(BigDecimal tauxReduction) {
        this.tauxReduction = tauxReduction;
    }

    public Produit getProduitCondition() {
        return produitCondition;
    }

    public void setProduitCondition(Produit produitCondition) {
        this.produitCondition = produitCondition;
    }

    public Integer getQuantiteCondition() {
        return quantiteCondition;
    }

    public void setQuantiteCondition(Integer quantiteCondition) {
        this.quantiteCondition = quantiteCondition;
    }

    public Produit getProduitOffert() {
        return produitOffert;
    }

    public void setProduitOffert(Produit produitOffert) {
        this.produitOffert = produitOffert;
    }

    public Integer getQuantiteOfferte() {
        return quantiteOfferte;
    }

    public void setQuantiteOfferte(Integer quantiteOfferte) {
        this.quantiteOfferte = quantiteOfferte;
    }

    public Integer getSeuilQuantite() {
        return seuilQuantite;
    }

    public void setSeuilQuantite(Integer seuilQuantite) {
        this.seuilQuantite = seuilQuantite;
    }

    public CatégorieProduit getCategorie() {
        return categorie;
    }

    public void setCategorie(CatégorieProduit categorie) {
        this.categorie = categorie;
    }

    public Set<Produit> getProduits() {
        return produits;
    }

    public void setProduits(Set<Produit> produits) {
        this.produits = produits;
    }

    public Set<LigneCommande> getLignesCommandes() {
        return lignesCommandes;
    }

    public void setLignesCommandes(Set<LigneCommande> lignesCommandes) {
        this.lignesCommandes = lignesCommandes;
    }

    public Commande getCommande() {
        return commande;
    }

    public void setCommande(Commande commande) {
        this.commande = commande;
    }

    // === TPR & LPR ===
    private BigDecimal discountValue;     // Valeur fixe (LPR)
    private BigDecimal tauxReduction;     // Pourcentage (TPR)

    // === GIFT OFFER ===
    @ManyToOne
    @JoinColumn(name = "produit_condition_id")
    private Produit produitCondition;     // Ex : shampoing

    private Integer quantiteCondition;    // Ex : 2 shampoings

    @ManyToOne
    @JoinColumn(name = "produit_offert_id")
    private Produit produitOffert;        // Ex : 1 après-shampoing offert

    private Integer quantiteOfferte;      // Ex : 1

    // === REBATE VOLUME ===
    private Integer seuilQuantite;        // Seuil pour déclencher la remise (ex : 1000 unités/mois)

    // === CIBLAGE ===
    @ManyToOne
    @JoinColumn(name = "categorie_id")
    private CatégorieProduit categorie;

    @ManyToMany(mappedBy = "promotions", cascade = CascadeType.PERSIST)
    @JsonIgnore
    private Set<Produit> produits = new HashSet<>();

    @ManyToMany(mappedBy = "promotions")
    private Set<LigneCommande> lignesCommandes = new HashSet<>();

    @ManyToOne
    @JoinColumn(name = "commande_id")
    @JsonBackReference
    private Commande commande;

    public Promotion() {}

    // === LOGIQUE MÉTIER ADAPTÉE AU TYPE DE PROMOTION ===

    public boolean estApplicable(Produit produit, int quantite) {
        LocalDate today = LocalDate.now();

        // Vérifier la validité des dates (inclus la borne)
        if ((dateDebut != null && today.isBefore(dateDebut)) ||
                (dateFin != null && today.isAfter(dateFin))) {
            return false;
        }

        // Vérifier si la promotion cible certains produits explicitement
        if (produits != null && !produits.isEmpty()) {
            boolean produitCible = produits.stream()
                    .anyMatch(p -> p.getId().equals(produit.getId()));
            if (!produitCible) {
                return false;
            }
        }

        // Vérifier la catégorie si elle est définie
        if (categorie != null) {
            if (produit.getCategorie() == null ||
                    !categorie.getId().equals(produit.getCategorie().getId())) {
                return false;
            }
        }

        // Cas spécifique type CADEAU
        if (type == TypePromotion.CADEAU) {
            if (produitCondition == null) {
                // Pas de produitCondition => pas applicable
                return false;
            }
            // Vérifie que c'est bien le produit condition ET quantité suffisante
            if (!produit.getId().equals(produitCondition.getId())) {
                return false;
            }
            if (quantite < quantiteCondition) {
                return false;
            }
            return true;
        }

        // Pour les autres types, on considère la promo applicable
        return true;
    }

    public BigDecimal calculerReduction(BigDecimal montant, int quantite) {
        switch (type) {
            case TPR:
                return montant.multiply(tauxReduction).setScale(2, RoundingMode.HALF_UP);
            case LPR:
                return discountValue.setScale(2, RoundingMode.HALF_UP);
            case REMISE:
                if (quantite >= seuilQuantite && tauxReduction != null) {
                    return montant.multiply(tauxReduction).setScale(2, RoundingMode.HALF_UP);
                }
                return BigDecimal.ZERO;
            default:
                return BigDecimal.ZERO;
        }
    }

    // GETTERS & SETTERS (à compléter pour les nouveaux champs)
}
