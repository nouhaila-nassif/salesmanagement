package com.example.backend.entity;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;

@Entity
@DiscriminatorValue("VENDEUR")
public  class Vendeur extends Utilisateur {

    @Override
    @Transient
    @JsonProperty("role")
    public String getRole() {
        return "VENDEUR";
    }

    // Tu peux laisser le reste vide si tu n’as pas de propriétés spécifiques
}
