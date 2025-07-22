package com.example.backend.dto;

import java.util.List;

public class UtilisateurDTO {
    private Long id;
    private String nomUtilisateur;
    private String telephone;     // ajout
    private String email;         // ajout
    private List<RouteDTO> routes;
    private List<CommandeDTO> commandes;
    private SuperviseurResponse superviseur;

    public UtilisateurDTO() {}

    public UtilisateurDTO(Long id, String nomUtilisateur, String telephone, String email,
                          List<RouteDTO> routes, List<CommandeDTO> commandes) {
        this.id = id;
        this.nomUtilisateur = nomUtilisateur;
        this.telephone = telephone;
        this.email = email;
        this.routes = routes;
        this.commandes = commandes;
    }

    // Getters

    public Long getId() {
        return id;
    }

    public String getNomUtilisateur() {
        return nomUtilisateur;
    }

    public String getTelephone() {
        return telephone;
    }

    public String getEmail() {
        return email;
    }

    public List<RouteDTO> getRoutes() {
        return routes;
    }

    public List<CommandeDTO> getCommandes() {
        return commandes;
    }

    public SuperviseurResponse getSuperviseur() {
        return superviseur;
    }

    // Setters

    public void setId(Long id) {
        this.id = id;
    }

    public void setNomUtilisateur(String nomUtilisateur) {
        this.nomUtilisateur = nomUtilisateur;
    }

    public void setTelephone(String telephone) {
        this.telephone = telephone;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public void setRoutes(List<RouteDTO> routes) {
        this.routes = routes;
    }

    public void setCommandes(List<CommandeDTO> commandes) {
        this.commandes = commandes;
    }

    public void setSuperviseur(SuperviseurResponse superviseur) {
        this.superviseur = superviseur;
    }
}
