package com.example.backend.dto;

import java.util.List;

public class StockCamionDto {
    private Long id;
    private String chauffeur;
    private List<ProduitStockDto> niveauxStock;

    // Constructeur sans argument (utile pour la sérialisation JSON)
    public StockCamionDto() {
    }

    // Constructeur avec tous les champs
    public StockCamionDto(Long id, String chauffeur, List<ProduitStockDto> niveauxStock) {
        this.id = id;
        this.chauffeur = chauffeur;
        this.niveauxStock = niveauxStock;
    }

    // Getters et setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getChauffeur() {
        return chauffeur;
    }

    public void setChauffeur(String chauffeur) {
        this.chauffeur = chauffeur;
    }

    public List<ProduitStockDto> getNiveauxStock() {
        return niveauxStock;
    }

    public void setNiveauxStock(List<ProduitStockDto> niveauxStock) {
        this.niveauxStock = niveauxStock;
    }
}
