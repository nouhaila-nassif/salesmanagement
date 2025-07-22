package com.example.backend.dto;

import com.example.backend.entity.Client;
import com.example.backend.entity.TypeClient;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

public class ClientResponseDTO {
    private Long id;
    private String nom;
    private String email;
    private TypeClient type;
    private String telephone;
    private String adresse;
    private List<RouteNomDTO> routes;
    private LocalDate derniereVisite;

    public String getTelephone() {
        return telephone;
    }

    public void setTelephone(String telephone) {
        this.telephone = telephone;
    }

    public LocalDate getDerniereVisite() {
        return derniereVisite;
    }

    public void setDerniereVisite(LocalDate derniereVisite) {
        this.derniereVisite = derniereVisite;
    }
// Constructeur, getters et setters

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
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

    public String getAdresse() {
        return adresse;
    }

    public void setAdresse(String adresse) {
        this.adresse = adresse;
    }

    public List<RouteNomDTO> getRoutes() {
        return routes;
    }

    public void setRoutes(List<RouteNomDTO> routes) {
        this.routes = routes;
    }

    public ClientResponseDTO() {
    }

    public ClientResponseDTO(Long id, String nom, String email, TypeClient type, String adresse, List<RouteNomDTO> routes) {
        this.id = id;
        this.nom = nom;
        this.email = email;
        this.type = type;
        this.adresse = adresse;
        this.routes = routes;
    }

    public ClientResponseDTO(Client client) {
        this.id = client.getId();
        this.nom = client.getNom();
        this.type = client.getType();
        this.telephone = client.getTelephone();
        this.email = client.getEmail();
        this.adresse = client.getAdresse();
        this.derniereVisite = client.getDerniereVisite();

        this.routes = client.getRoutes() != null
                ? client.getRoutes().stream()
                .map(route -> new RouteNomDTO(route.getId(), route.getNom()))
                .collect(Collectors.toList()) // ✅ Correction ici
                : null;
    }

}
