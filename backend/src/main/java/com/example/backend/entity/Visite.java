package com.example.backend.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;

import java.time.LocalDate;

@Entity
public class Visite {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "client_id", nullable = false)
    @JsonIgnoreProperties({"visites", "hibernateLazyInitializer", "handler"})
    private Client client;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vendeur_id", nullable = false)
    @JsonIgnoreProperties({"visites", "hibernateLazyInitializer", "handler"})
    private Utilisateur vendeur;  // ✅ Accept any type of seller

    private LocalDate datePlanifiee;
    private LocalDate dateReelle;

    @Enumerated(EnumType.STRING)
    private StatutVisite statut;

    // Getters et setters

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Client getClient() {
        return client;
    }

    public void setClient(Client client) {
        this.client = client;
    }

    public Utilisateur getVendeur() {
        return vendeur;
    }

    public void setVendeur(Utilisateur vendeur) {
        this.vendeur = vendeur;
    }

    public LocalDate getDatePlanifiee() {
        return datePlanifiee;
    }

    public void setDatePlanifiee(LocalDate datePlanifiee) {
        this.datePlanifiee = datePlanifiee;
    }

    public LocalDate getDateReelle() {
        return dateReelle;
    }

    public void setDateReelle(LocalDate dateReelle) {
        this.dateReelle = dateReelle;
    }

    public StatutVisite getStatut() {
        return statut;
    }

    public void setStatut(StatutVisite statut) {
        this.statut = statut;
    }
}
