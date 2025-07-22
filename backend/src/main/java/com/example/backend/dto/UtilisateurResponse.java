package com.example.backend.dto;

import com.example.backend.entity.PreVendeur;
import com.example.backend.entity.Superviseur;
import com.example.backend.entity.Utilisateur;
import com.example.backend.entity.VendeurDirect;
import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.ALWAYS) // Modifié ici
public class UtilisateurResponse {

    private Long id;
    private String nomUtilisateur;
    private String role;
    private String telephone;
    private String email;
    private Long superviseurId;      // facultatif, rempli si VENDEURDIRECT
    private String superviseurNom;
    public UtilisateurResponse(Utilisateur user) {
        this.id = user.getId();
        this.nomUtilisateur = user.getNomUtilisateur();
        this.role = user.getRole();
        this.telephone = user.getTelephone();
        this.email = user.getEmail();

        if (( "VENDEURDIRECT".equalsIgnoreCase(user.getRole()) || "PREVENDEUR".equalsIgnoreCase(user.getRole()) )
                && user.getSuperviseur() != null) {
            this.superviseurId = user.getSuperviseur().getId();
            this.superviseurNom = user.getSuperviseur().getNomUtilisateur();
        }
    }

    public Long getId() {
        return id;
    }

    public String getSuperviseurNom() {
        return superviseurNom;
    }

    public void setSuperviseurNom(String superviseurNom) {
        this.superviseurNom = superviseurNom;
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
    // Getters et Setters (ajoutez pour superviseurId)
    public Long getSuperviseurId() {
        return superviseurId;
    }

    public void setSuperviseurId(Long superviseurId) {
        this.superviseurId = superviseurId;
    }
}
