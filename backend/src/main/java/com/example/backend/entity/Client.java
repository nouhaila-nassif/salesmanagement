package com.example.backend.entity;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonManagedReference;
import jakarta.persistence.*;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Entity
public class Client {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // auto-increment
    private Long id;

    private String nom;

    @Enumerated(EnumType.STRING)
    private TypeClient type;

    private String telephone;

    private String email;

    private String adresse;

    private LocalDate derniereVisite;

    @ManyToMany
    @JoinTable(
            name = "client_route",
            joinColumns = @JoinColumn(name = "client_id"),
            inverseJoinColumns = @JoinColumn(name = "route_id")
    )
    @JsonIgnore
    private Set<Route> routes = new HashSet<>();



    // Relations OneToMany vers Commande avec nom spécifique dans @JsonBackReference
    @OneToMany(mappedBy = "client")
    @JsonBackReference(value = "client-commande")
    private List<Commande> commandes;

    // Relations OneToMany vers Visite avec nom spécifique dans @JsonBackReference
    @OneToMany(mappedBy = "client")
    @JsonBackReference(value = "client-visite")
    private List<Visite> visites;

    public Client() {}

    // Getters & Setters

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public TypeClient getType() { return type; }
    public void setType(TypeClient type) { this.type = type; }

    public String getTelephone() { return telephone; }
    public void setTelephone(String telephone) { this.telephone = telephone; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getAdresse() { return adresse; }
    public void setAdresse(String adresse) { this.adresse = adresse; }

    public LocalDate getDerniereVisite() { return derniereVisite; }
    public void setDerniereVisite(LocalDate derniereVisite) { this.derniereVisite = derniereVisite; }

    public Set<Route> getRoutes() {
        return routes;
    }

    public void setRoutes(Set<Route> routes) {
        this.routes = routes;
    }

    public List<Commande> getCommandes() { return commandes; }
    public void setCommandes(List<Commande> commandes) { this.commandes = commandes; }

    public List<Visite> getVisites() { return visites; }
    public void setVisites(List<Visite> visites) { this.visites = visites; }
}
