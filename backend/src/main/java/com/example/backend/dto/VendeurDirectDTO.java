package com.example.backend.dto;

import com.example.backend.entity.Utilisateur;

public class VendeurDirectDTO {
    private Long id;
    private String nomUtilisateur;
    private String telephone;
    private String email;
    private Long superviseurId;
    private String superviseurNom;

    // Constructeur à partir de l'entité
    public VendeurDirectDTO(Utilisateur vendeur) {
        this.id = vendeur.getId();
        this.nomUtilisateur = vendeur.getNomUtilisateur();
        this.telephone = vendeur.getTelephone();
        this.email = vendeur.getEmail();
        this.superviseurId = vendeur.getSuperviseur().getId();
        this.superviseurNom = vendeur.getSuperviseur().getNomUtilisateur();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNomUtilisateur() {
        return nomUtilisateur;
    }

    public void setNomUtilisateur(String nomUtilisateur) {
        this.nomUtilisateur = nomUtilisateur;
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

    public Long getSuperviseurId() {
        return superviseurId;
    }

    public void setSuperviseurId(Long superviseurId) {
        this.superviseurId = superviseurId;
    }

    public String getSuperviseurNom() {
        return superviseurNom;
    }

    public void setSuperviseurNom(String superviseurNom) {
        this.superviseurNom = superviseurNom;
    }
// Getters et setters
    // ...
}
