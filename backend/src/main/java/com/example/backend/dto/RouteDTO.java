package com.example.backend.dto;

import java.util.List;

public class RouteDTO {
    private Long id;
    private String nom;
    private List<Long> vendeurIds;
    private List<Long> clientIds;

    // Constructeurs
    public RouteDTO() {}

    public RouteDTO(Long id, String nom) {
        this.id = id;
        this.nom = nom;
    }

    // Getters et Setters
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

    public List<Long> getVendeurIds() {
        return vendeurIds;
    }

    public void setVendeurIds(List<Long> vendeurIds) {
        this.vendeurIds = vendeurIds;
    }

    public List<Long> getClientIds() {
        return clientIds;
    }

    public void setClientIds(List<Long> clientIds) {
        this.clientIds = clientIds;
    }
}
