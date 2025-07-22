package com.example.backend.dto;

import com.example.backend.entity.Promotion;
import com.example.backend.entity.TypePromotion;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public class PromotionDTO {

    private Long id;
    private String nom;
    private TypePromotion type;
    private LocalDate dateDebut;
    private LocalDate dateFin;
    // ✅ Nouveau champ pour lier des produits
    private List<Long> produitsIds;
    // Pour TPR et REMISE
    private BigDecimal tauxReduction;

    public List<Long> getProduitsIds() {
        return produitsIds;
    }

    public void setProduitsIds(List<Long> produitsIds) {
        this.produitsIds = produitsIds;
    }

    // Pour LPR
    private BigDecimal discountValue;

    // Pour REMISE
    private Integer seuilQuantite;

    // Pour CADEAU - on remplace l'ID par le nom uniquement
    private String produitConditionNom;
    private Integer quantiteCondition;
    private String produitOffertNom;
    private Integer quantiteOfferte;

    // Catégorie complète
    private CatégorieProduitDTO categorie;

    // --- Constructeurs ---
    public PromotionDTO() {}

    public PromotionDTO(Promotion promo) {
        if (promo == null) return;

        this.id = promo.getId();
        this.nom = promo.getNom();
        this.type = promo.getType();
        this.dateDebut = promo.getDateDebut();
        this.dateFin = promo.getDateFin();
        this.tauxReduction = promo.getTauxReduction();
        this.discountValue = promo.getDiscountValue();
        this.seuilQuantite = promo.getSeuilQuantite();

        if (promo.getProduitCondition() != null) {
            this.produitConditionNom = promo.getProduitCondition().getNom();
        }

        if (promo.getProduitOffert() != null) {
            this.produitOffertNom = promo.getProduitOffert().getNom();
        }

        this.quantiteCondition = promo.getQuantiteCondition();
        this.quantiteOfferte = promo.getQuantiteOfferte();

        if (promo.getCategorie() != null) {
            this.categorie = new CatégorieProduitDTO(
                    promo.getCategorie().getId(),
                    promo.getCategorie().getNom(),
                    promo.getCategorie().getDescription()
            );
        }
    }

    // --- Getters & Setters ---

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public TypePromotion getType() { return type; }
    public void setType(TypePromotion type) { this.type = type; }

    public LocalDate getDateDebut() { return dateDebut; }
    public void setDateDebut(LocalDate dateDebut) { this.dateDebut = dateDebut; }

    public LocalDate getDateFin() { return dateFin; }
    public void setDateFin(LocalDate dateFin) { this.dateFin = dateFin; }

    public BigDecimal getTauxReduction() { return tauxReduction; }
    public void setTauxReduction(BigDecimal tauxReduction) { this.tauxReduction = tauxReduction; }

    public BigDecimal getDiscountValue() { return discountValue; }
    public void setDiscountValue(BigDecimal discountValue) { this.discountValue = discountValue; }

    public Integer getSeuilQuantite() { return seuilQuantite; }
    public void setSeuilQuantite(Integer seuilQuantite) { this.seuilQuantite = seuilQuantite; }

    public String getProduitConditionNom() { return produitConditionNom; }
    public void setProduitConditionNom(String produitConditionNom) { this.produitConditionNom = produitConditionNom; }

    public Integer getQuantiteCondition() { return quantiteCondition; }
    public void setQuantiteCondition(Integer quantiteCondition) { this.quantiteCondition = quantiteCondition; }

    public String getProduitOffertNom() { return produitOffertNom; }
    public void setProduitOffertNom(String produitOffertNom) { this.produitOffertNom = produitOffertNom; }

    public Integer getQuantiteOfferte() { return quantiteOfferte; }
    public void setQuantiteOfferte(Integer quantiteOfferte) { this.quantiteOfferte = quantiteOfferte; }

    public CatégorieProduitDTO getCategorie() { return categorie; }
    public void setCategorie(CatégorieProduitDTO categorie) { this.categorie = categorie; }
}
