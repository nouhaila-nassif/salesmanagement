package com.example.backend.dto;

public class VendeurDirectUpdateDTO {
    private String nomUtilisateur;
    private String motDePasse;
    private Long superviseurId;

    // Constructeur par défaut
    public VendeurDirectUpdateDTO() {}

    // Getters
    public String getNomUtilisateur() {
        return nomUtilisateur;
    }

    public String getMotDePasse() {
        return motDePasse;
    }

    public Long getSuperviseurId() {
        return superviseurId;
    }

    // Setters
    public void setNomUtilisateur(String nomUtilisateur) {
        this.nomUtilisateur = nomUtilisateur;
    }

    public void setMotDePasse(String motDePasse) {
        this.motDePasse = motDePasse;
    }

    public void setSuperviseurId(Long superviseurId) {
        this.superviseurId = superviseurId;
    }
}