package com.example.backend.entity;


import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;


@Entity
@DiscriminatorValue("VENDEUR_DIRECT")
public class VendeurDirect extends Vendeur {
    @Override
    public String getRole() {
        return "VENDEURDIRECT";
    }




// ... getters/setters ...
}