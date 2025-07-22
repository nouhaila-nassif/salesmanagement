package com.example.backend.dto;

public class UpdateUtilisateurRequest {

    private String nomUtilisateur;
    private String userType;
    private String motDePasse; // mot de passe en clair, à encoder
    private String telephone;
    private String email;
    private Long superviseurId; // utile uniquement pour les vendeurs

    public UpdateUtilisateurRequest() {}

    public UpdateUtilisateurRequest(String nomUtilisateur, String userType, String telephone, String email, Long superviseurId) {
        this.nomUtilisateur = nomUtilisateur;
        this.userType = userType;
        this.telephone = telephone;
        this.email = email;
        this.superviseurId = superviseurId;
    }

    // Getters & Setters

    public String getNomUtilisateur() {
        return nomUtilisateur;
    }

    public void setNomUtilisateur(String nomUtilisateur) {
        this.nomUtilisateur = nomUtilisateur;
    }

    public String getUserType() {
        return userType;
    }

    public void setUserType(String userType) {
        this.userType = userType;
    }

    public String getMotDePasse() {
        return motDePasse;
    }

    public void setMotDePasse(String motDePasse) {
        this.motDePasse = motDePasse;
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
}
