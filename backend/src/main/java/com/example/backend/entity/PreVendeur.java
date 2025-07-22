package com.example.backend.entity;


import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
@Entity
@PrimaryKeyJoinColumn(name = "vendeur_id")
public class PreVendeur extends Vendeur {
    @Override
    public String getRole() {
        return "PREVENDEUR";
    }
    @OneToMany(mappedBy = "vendeur", cascade = CascadeType.ALL)
    private List<Visite> visites = new ArrayList<>();

        public List<Visite> getVisites() {
        return visites;
    }

    public void setVisites(List<Visite> visites) {
        this.visites = visites;
    }


// ... getters, setters ...
}