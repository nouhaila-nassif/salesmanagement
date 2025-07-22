package com.example.backend.dto;

import com.example.backend.entity.PreVendeur;

public class PreVendeurDTO {

    private Long id;
    private String nomUtilisateur;
    private String role;
    private String telephone;
    private String email;
    private Long superviseurId;
    private String superviseurNom;

    public PreVendeurDTO() {}

    public PreVendeurDTO(PreVendeur preVendeur) {
        this.id = preVendeur.getId();
        this.nomUtilisateur = preVendeur.getNomUtilisateur();
        this.role = preVendeur.getRole(); // Assure-toi que la méthode getRole() renvoie "PREVENDEUR" ou équivalent
        this.telephone = preVendeur.getTelephone();
        this.email = preVendeur.getEmail();

        if (preVendeur.getSuperviseur() != null) {
            this.superviseurId = preVendeur.getSuperviseur().getId();
            this.superviseurNom = preVendeur.getSuperviseur().getNomUtilisateur();
        }
    }

    // Getters et setters

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

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
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
}
