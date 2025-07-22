package com.example.backend.entity;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonManagedReference;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Entity
@Inheritance(strategy = InheritanceType.JOINED)
@DiscriminatorColumn(name = "user_type")
public abstract class Utilisateur {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "superviseur_id")
    private Utilisateur superviseur;


    public Utilisateur getSuperviseur() {
        return superviseur;
    }

    public void setSuperviseur(Utilisateur superviseur) {
        this.superviseur = superviseur;
    }

    @OneToMany(mappedBy = "superviseur")
    private List<Utilisateur> supervises;
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String nomUtilisateur;

    private String email;

    @Column(length = 20)
    private String telephone;

    @Column(nullable = false)
    private String motDePasseHash;

    @OneToMany(mappedBy = "approuvePar")
    @JsonManagedReference("approuve-par-commande")
    private List<Produit> produitsApprouves = new ArrayList<>();

    @ManyToMany(mappedBy = "vendeurs")
    @JsonIgnore
    private Set<Route> routes = new HashSet<>();

    @OneToMany(mappedBy = "vendeur")
    @JsonBackReference(value = "commande-vendeur")
    private List<Commande> commandes = new ArrayList<>();

    public Utilisateur() {
        // Constructeur par défaut requis par JPA
    }

    // Méthode abstraite pour récupérer le rôle, exposée en JSON sous "role"
    @Transient
    @JsonProperty("role")
    public abstract String getRole();

    // Getters & Setters

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

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getTelephone() {
        return telephone;
    }

    public void setTelephone(String telephone) {
        this.telephone = telephone;
    }

    public String getMotDePasseHash() {
        return motDePasseHash;
    }

    public void setMotDePasseHash(String motDePasseHash) {
        this.motDePasseHash = motDePasseHash;
    }

    public List<Produit> getProduitsApprouves() {
        return produitsApprouves;
    }

    public void setProduitsApprouves(List<Produit> produitsApprouves) {
        this.produitsApprouves = produitsApprouves;
    }

    public Set<Route> getRoutes() {
        return routes;
    }

    public void setRoutes(Set<Route> routes) {
        this.routes = routes;
    }

    public List<Commande> getCommandes() {
        return commandes;
    }

    public void setCommandes(List<Commande> commandes) {
        this.commandes = commandes;
    }
}
