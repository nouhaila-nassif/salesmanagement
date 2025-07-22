package com.example.backend.dto;

import com.example.backend.entity.Client;
import com.example.backend.entity.Route;
import com.example.backend.entity.TypeClient;

import java.time.LocalDate;
import java.util.Set;
import java.util.stream.Collectors;

public class ClientDTO {
    private Long id;
    private String nom;
    private TypeClient type;
    private String telephone;
    private String email;
    private String adresse;
    private LocalDate derniereVisite;
    private Set<RouteNomDTO> routes;  // Set car relation ManyToMany

    // Constructeur sans argument
    public ClientDTO() {}

    // Constructeur complet


    public ClientDTO(Long id, String nom, TypeClient type, String telephone, String email, String adresse, LocalDate derniereVisite, Set<RouteNomDTO> routes) {
        this.id = id;
        this.nom = nom;
        this.type = type;
        this.telephone = telephone;
        this.email = email;
        this.adresse = adresse;
        this.derniereVisite = derniereVisite;
        this.routes = routes;
    }

    public ClientDTO(Client client) {
        this.id = client.getId();
        this.nom = client.getNom();
        this.type = client.getType();
        this.telephone = client.getTelephone();
        this.email = client.getEmail();
        this.adresse = client.getAdresse();
        this.derniereVisite = client.getDerniereVisite();

        this.routes = client.getRoutes() != null
                ? client.getRoutes().stream()
                .map(route -> new RouteNomDTO(route.getId(), route.getNom())) // ✅ Ajouter l'id ici
                .collect(Collectors.toSet())
                : null;
    }

    // Getters et setters
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

    public TypeClient getType() {
        return type;
    }

    public void setType(TypeClient type) {
        this.type = type;
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

    public Set<RouteNomDTO> getRoutes() {
        return routes;
    }

    public void setRoutes(Set<RouteNomDTO> routes) {
        this.routes = routes;
    }
}
