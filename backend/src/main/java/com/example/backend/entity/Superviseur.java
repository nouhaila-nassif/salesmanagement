package com.example.backend.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonManagedReference;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Entity
public class Superviseur extends Utilisateur {
    @Override
    public String getRole() {
        return "SUPERVISEUR";
    }    @ManyToOne
    @JoinColumn(name = "responsable_id")
    private ResponsableUnite responsable;


    public ResponsableUnite getResponsable() {
        return responsable;
    }

    public void setResponsable(ResponsableUnite responsable) {
        this.responsable = responsable;
    }

    @OneToMany(mappedBy = "superviseur", cascade = CascadeType.ALL)
    @JsonManagedReference
    private List<PreVendeur> preVendeurs;


    @OneToMany(mappedBy = "superviseur")
    @JsonIgnore
    private List<VendeurDirect> vendeursDirects;

    public List<PreVendeur> getPreVendeurs() {
        return preVendeurs;
    }

    public void setPreVendeurs(List<PreVendeur> preVendeurs) {
        this.preVendeurs = preVendeurs;
    }

    public List<VendeurDirect> getVendeursDirects() {
        return vendeursDirects;
    }

    public void setVendeursDirects(List<VendeurDirect> vendeursDirects) {
        this.vendeursDirects = vendeursDirects;
    }
}
