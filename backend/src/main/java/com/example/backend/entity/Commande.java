package com.example.backend.entity;

import com.fasterxml.jackson.annotation.JsonIdentityInfo;
import com.fasterxml.jackson.annotation.ObjectIdGenerators;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Entity
@JsonIdentityInfo(
        generator = ObjectIdGenerators.PropertyGenerator.class,
        property = "id"
)
public class Commande {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private LocalDate dateLivraison;
    private LocalDate dateCreation;

    public Commande() {
    }

    @Enumerated(EnumType.STRING)
    private StatutCommande statut;

    public Commande(Long id, LocalDate dateLivraison, LocalDate dateCreation, StatutCommande statut, Utilisateur vendeur, Utilisateur approuvePar, Client client, List<LigneCommande> lignes, Set<Promotion> promotions, BigDecimal montantTotal, BigDecimal montantTotalAvantRemise, BigDecimal montantReduction, BigDecimal prixUnitaire) {
        this.id = id;
        this.dateLivraison = dateLivraison;
        this.dateCreation = dateCreation;
        this.statut = statut;
        this.vendeur = vendeur;
        this.approuvePar = approuvePar;
        this.client = client;
        this.lignes = lignes;
        this.promotions = promotions;
        this.montantTotal = montantTotal;
        this.montantTotalAvantRemise = montantTotalAvantRemise;
        this.montantReduction = montantReduction;
        this.prixUnitaire = prixUnitaire;
    }

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "vendeur_id")
    private Utilisateur vendeur;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "approuve_par_id")
    private Utilisateur approuvePar;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "client_id")
    private Client client;

    @OneToMany(mappedBy = "commande", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<LigneCommande> lignes = new ArrayList<>();

    @ManyToMany(fetch = FetchType.LAZY) // ou EAGER pour le debug
    @JoinTable(
            name = "commande_promotion",
            joinColumns = @JoinColumn(name = "commande_id"),
            inverseJoinColumns = @JoinColumn(name = "promotion_id")
    )
    private Set<Promotion> promotions;


    @ManyToMany
    @JoinTable(
            name = "commande_promotions_cadeaux",
            joinColumns = @JoinColumn(name = "commande_id"),
            inverseJoinColumns = @JoinColumn(name = "promotion_id"),
            uniqueConstraints = @UniqueConstraint(columnNames = {"commande_id", "promotion_id"})
    )
    private Set<Promotion> promotionsCadeaux = new HashSet<>();

    public Set<Promotion> getPromotionsCadeaux() {
        return promotionsCadeaux;
    }

    public void setPromotionsCadeaux(Set<Promotion> promotionsCadeaux) {
        this.promotionsCadeaux = promotionsCadeaux;
    }

    private BigDecimal montantTotal = BigDecimal.ZERO;
    @Column(precision = 10, scale = 2)
    private BigDecimal montantTotalAvantRemise;
    public BigDecimal getMontantTotalAvantRemise() {
        return montantTotalAvantRemise;
    }


    public void setMontantTotalAvantRemise(BigDecimal montantTotalAvantRemise) {
        this.montantTotalAvantRemise = montantTotalAvantRemise;
    }

    // 🔽 AJOUTÉ ICI : montant de la réduction
    private BigDecimal montantReduction = BigDecimal.ZERO;

    // 🔽 (Optionnel) pour compatibilité avec code existant
    private BigDecimal prixUnitaire;


    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public LocalDate getDateLivraison() { return dateLivraison; }
    public void setDateLivraison(LocalDate dateLivraison) { this.dateLivraison = dateLivraison; }

    public LocalDate getDateCreation() { return dateCreation; }
    public void setDateCreation(LocalDate dateCreation) { this.dateCreation = dateCreation; }

    public StatutCommande getStatut() { return statut; }
    public void setStatut(StatutCommande statut) { this.statut = statut; }

    public Utilisateur getVendeur() { return vendeur; }
    public void setVendeur(Utilisateur vendeur) { this.vendeur = vendeur; }

    public Utilisateur getApprouvePar() { return approuvePar; }
    public void setApprouvePar(Utilisateur approuvePar) { this.approuvePar = approuvePar; }

    public Client getClient() { return client; }
    public void setClient(Client client) { this.client = client; }

    public List<LigneCommande> getLignes() { return lignes; }
    public void setLignes(List<LigneCommande> lignes) { this.lignes = lignes; }

    public Set<Promotion> getPromotions() { return promotions; }
    public void setPromotions(Set<Promotion> promotions) { this.promotions = promotions; }



    public BigDecimal getMontantTotal() { return montantTotal; }
    public void setMontantTotal(BigDecimal montantTotal) { this.montantTotal = montantTotal; }

    public BigDecimal getPrixUnitaire() { return prixUnitaire; }
    public void setPrixUnitaire(BigDecimal prixUnitaire) { this.prixUnitaire = prixUnitaire; }

    // 🔽 Ajout des getters/setters pour montantReduction

    public BigDecimal getMontantReduction() {
        return montantReduction;
    }

    public void setMontantReduction(BigDecimal montantReduction) {
        this.montantReduction = montantReduction;
    }

    // 🔽 Méthode utilitaire pour obtenir le total net (facultatif)
    public BigDecimal getMontantNet() {
        return calculerMontantTotal().subtract(montantReduction != null ? montantReduction : BigDecimal.ZERO);
    }

    public BigDecimal calculerMontantTotal() {
        if (lignes == null) return BigDecimal.ZERO;

        BigDecimal total = BigDecimal.ZERO;
        for (LigneCommande ligne : lignes) {
            BigDecimal prix = BigDecimal.valueOf(ligne.getProduit().getPrixUnitaire());
            BigDecimal quantite = BigDecimal.valueOf(ligne.getQuantite());
            total = total.add(prix.multiply(quantite));
        }
        return total.setScale(2, RoundingMode.HALF_UP);
    }



}
