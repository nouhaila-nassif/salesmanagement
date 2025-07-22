package com.example.backend.entity;

import jakarta.persistence.Entity;

@Entity
public class Administrateur extends Utilisateur {
    @Override
    public String getRole() {
        return "ADMIN";
    }}