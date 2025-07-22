package com.example.backend.dto;

import com.example.backend.entity.Client;
import com.example.backend.entity.TypeClient;

import java.time.LocalDate;

public class CreateClientRequest {

    private String nom;
    private String telephone;
    private String email;
    private String adresse;
    private LocalDate derniereVisite;
    private TypeClient type;
    private Long routeId;

    // Constructeur vide requis pour la désérialisation JSON
    public CreateClientRequest() {}

    // Getters et setters

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public String getTelephone() {
        return telephone;
    }

    public void setTelephone(String telephone) {
        this.telephone = telephone;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getAdresse() {
        return adresse;
    }

    public void setAdresse(String adresse) {
        this.adresse = adresse;
    }

    public LocalDate getDerniereVisite() {
        return derniereVisite;
    }

    public void setDerniereVisite(LocalDate derniereVisite) {
        this.derniereVisite = derniereVisite;
    }

    public TypeClient getType() {
        return type;
    }

    public void setType(TypeClient type) {
        this.type = type;
    }

    public Long getRouteId() {
        return routeId;
    }

    public void setRouteId(Long routeId) {
        this.routeId = routeId;
    }

    // Transformation en entité Client (sans route, c'est normal)
    public Client toClient() {
        Client client = new Client();
        client.setNom(this.nom);
        client.setTelephone(this.telephone);
        client.setEmail(this.email);
        client.setAdresse(this.adresse);
        client.setDerniereVisite(this.derniereVisite);
        client.setType(this.type);
        return client;
    }

    @Override
    public String toString() {
        return "CreateClientRequest{" +
                "nom='" + nom + '\'' +
                ", telephone='" + telephone + '\'' +
                ", email='" + email + '\'' +
                ", adresse='" + adresse + '\'' +
                ", derniereVisite=" + derniereVisite +
                ", type=" + type +
                ", routeId=" + routeId +
                '}';
    }
}
