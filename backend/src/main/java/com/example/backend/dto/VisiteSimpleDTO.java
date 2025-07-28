package com.example.backend.dto;

import com.example.backend.entity.StatutVisite;
import com.example.backend.entity.TypeClient;

import java.time.LocalDate;

public class VisiteSimpleDTO {
    private Long id;
    private LocalDate datePlanifiee;
    private String nomClient;
    private String adresse;
    private String numeroTelephone;
    private String email;
    private String nomVendeur;
    private TypeClient typeClient;
    private StatutVisite statut;  // <-- ajouté

    public VisiteSimpleDTO() {
        // constructeur par défaut (obligatoire pour la désérialisation JSON)
    }

    public VisiteSimpleDTO(Long id, LocalDate datePlanifiee, String nomClient, String nomVendeur, TypeClient typeClient,
                           String adresse, String numeroTelephone, String email, StatutVisite statut) {
        this.id = id;
        this.datePlanifiee = datePlanifiee;
        this.nomClient = nomClient;
        this.nomVendeur = nomVendeur;
        this.typeClient = typeClient;
        this.adresse = adresse;
        this.numeroTelephone = numeroTelephone;
        this.email = email;
        this.statut = statut;   // initialisation

    }

    public StatutVisite getStatut() {
        return statut;
    }

    public void setStatut(StatutVisite statut) {
        this.statut = statut;
    }

    // Getters & Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public LocalDate getDatePlanifiee() {
        return datePlanifiee;
    }

    public void setDatePlanifiee(LocalDate datePlanifiee) {
        this.datePlanifiee = datePlanifiee;
    }

    public String getNomClient() {
        return nomClient;
    }

    public void setNomClient(String nomClient) {
        this.nomClient = nomClient;
    }

    public String getNomVendeur() {
        return nomVendeur;
    }

    public void setNomVendeur(String nomVendeur) {
        this.nomVendeur = nomVendeur;
    }

    public TypeClient getTypeClient() {
        return typeClient;
    }

    public void setTypeClient(TypeClient typeClient) {
        this.typeClient = typeClient;
    }

    public String getAdresse() {
        return adresse;
    }

    public void setAdresse(String adresse) {
        this.adresse = adresse;
    }

    public String getNumeroTelephone() {
        return numeroTelephone;
    }

    public void setNumeroTelephone(String numeroTelephone) {
        this.numeroTelephone = numeroTelephone;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}
