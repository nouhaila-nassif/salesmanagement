package com.example.backend.entity;

import com.fasterxml.jackson.annotation.*;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Set;

@JsonIdentityInfo(
        generator = ObjectIdGenerators.PropertyGenerator.class,
        property = "id"
)
@Entity
public class Produit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String embedding;

    public List<Double> getEmbeddingAsList() {
        ObjectMapper mapper = new ObjectMapper();
        try {
            return mapper.readValue(embedding, new TypeReference<List<Double>>() {});
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }

    private String nom;
    private String description;
    private String marque;
    private Float prixUnitaire;
    private String imageUrl;

    @Lob
    private String imageBase64;

    @ManyToOne
    @JsonBackReference // ou @JsonIgnore si tu ne veux pas remonter la catégorie
    private CatégorieProduit categorie;

    @ManyToMany
    @JoinTable(name = "promotion_produit")
    private Set<Promotion> promotions;

    @OneToMany(mappedBy = "produit")
    private List<LigneCommande> lignesCommande;

    @ManyToOne
    @JsonBackReference("approuve-par-commande") // <- important pour éviter la boucle
    @JoinColumn(name = "approuve_par_id")
    private Utilisateur approuvePar;


    // Constructeurs, getters et setters

    public Produit() {}

    // ... (constructeurs, getters/setters)

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Produit)) return false;
        Produit produit = (Produit) o;
        return Objects.equals(id, produit.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }

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

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getMarque() {
        return marque;
    }

    public void setMarque(String marque) {
        this.marque = marque;
    }

    public Float getPrixUnitaire() {
        return prixUnitaire != null ? prixUnitaire : 0f; // renvoyer 0 si null
    }

    public void setPrixUnitaire(Float prixUnitaire) {
        this.prixUnitaire = prixUnitaire;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public String getImageBase64() {
        return imageBase64;
    }

    public void setImageBase64(String imageBase64) {
        this.imageBase64 = imageBase64;
    }

    public CatégorieProduit getCategorie() {
        return categorie;
    }

    public void setCategorie(CatégorieProduit categorie) {
        this.categorie = categorie;
    }

    public Set<Promotion> getPromotions() {
        return promotions;
    }

    public void setPromotions(Set<Promotion> promotions) {
        this.promotions = promotions;
    }

    public List<LigneCommande> getLignesCommande() {
        return lignesCommande;
    }

    public void setLignesCommande(List<LigneCommande> lignesCommande) {
        this.lignesCommande = lignesCommande;
    }

    public Utilisateur getApprouvePar() {
        return approuvePar;
    }

    public void setApprouvePar(Utilisateur approuvePar) {
        this.approuvePar = approuvePar;
    }

    @Override
    public String toString() {
        return "Produit{" +
                "id=" + id +
                ", nom='" + nom + '\'' +
                ", marque='" + marque + '\'' +
                ", prixUnitaire=" + prixUnitaire +
                '}';
    }
}
