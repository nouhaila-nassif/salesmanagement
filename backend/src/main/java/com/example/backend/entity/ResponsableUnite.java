package com.example.backend.entity;

import jakarta.persistence.CascadeType;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import jakarta.persistence.OneToMany;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Entity
@DiscriminatorValue("RESPONSABLE_UNITE")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ResponsableUnite extends Utilisateur {
    @Override
    public String getRole() {
        return "RESPONSABLEUNITE";
    }

    @OneToMany(mappedBy = "responsable", cascade = CascadeType.ALL)
    private List<Superviseur> superviseurs;
    // Champs spécifiques au responsable d’unité

    public List<Superviseur> getSuperviseurs() {
        return superviseurs;
    }

    public void setSuperviseurs(List<Superviseur> superviseurs) {
        this.superviseurs = superviseurs;
    }
}

