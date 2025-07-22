package com.example.backend.dto;

import com.example.backend.entity.Superviseur;
import com.example.backend.entity.Utilisateur;

public class SuperviseurResponse {
    private Long id;
    private String nomUtilisateur;

    public SuperviseurResponse(Utilisateur utilisateur) {
        this.id = utilisateur.getId();
        this.nomUtilisateur = utilisateur.getNomUtilisateur();
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
}
