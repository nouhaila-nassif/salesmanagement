package com.example.backend.entity;

import jakarta.persistence.*;
import java.util.HashMap;
import java.util.Map;

@Entity
public class StockCamion {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "chauffeur_id")
    private VendeurDirect chauffeur;

    @ElementCollection
    @CollectionTable(
            name = "stock_camion_produits",
            joinColumns = @JoinColumn(name = "stock_camion_id")
    )
    @MapKeyJoinColumn(name = "produit_id")
    @Column(name = "quantite")
    private Map<Produit, Integer> niveauxStock = new HashMap<>();

    // ----- Méthodes métier utiles -----

    public void charger(Produit produit, int quantite) {
        niveauxStock.merge(produit, quantite, Integer::sum);
    }

    public void déduire(Produit produit, int quantite) {
        niveauxStock.computeIfPresent(produit, (p, q) -> {
            int newQte = q - quantite;
            return newQte > 0 ? newQte : 0;
        });
    }

    public boolean vérifierDisponibilité(Produit produit, int quantite) {
        return niveauxStock.getOrDefault(produit, 0) >= quantite;
    }

    // ----- Getters et Setters -----

    public Long getId() {
        return id;
    }

    public VendeurDirect getChauffeur() {
        return chauffeur;
    }

    public void setChauffeur(VendeurDirect chauffeur) {
        this.chauffeur = chauffeur;
    }

    public Map<Produit, Integer> getNiveauxStock() {
        return niveauxStock;
    }

    public void setNiveauxStock(Map<Produit, Integer> niveauxStock) {
        this.niveauxStock = niveauxStock;
    }
}
