package com.example.backend.dto;

import com.example.backend.entity.StatutCommande;
import com.fasterxml.jackson.annotation.JsonFormat; // Often useful for LocalDate/LocalDateTime serialization

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
// No need for 'import java.util.Set;' if you're consistently using List for promotionIds

public class CommandeDTO {
    private Long id;
    @JsonFormat(pattern = "yyyy-MM-dd") // Added for consistent date serialization/deserialization
    private LocalDate dateCreation;
    private StatutCommande statut;
    private Long clientId;
    private Long vendeurId;
    private Long approuveParId;
    private String vendeurNom;
    private String clientNom;
    private String approuveParNom;
    private List<LigneCommandeDTO> lignes;
    @JsonFormat(pattern = "yyyy-MM-dd") // Added for consistent date serialization/deserialization
    private LocalDate dateLivraison;
    private BigDecimal montantReduction;
    private BigDecimal montantTotal;
    private BigDecimal montantTotalAvantRemise;
    private List<Long> promotionIds; // This is the correct field for multiple promotions
    private List<String> produitsOffertsNoms;
    private List<PromotionCadeauInfo> promotionsCadeaux;
    private List<PromotionDTO> promotionsAppliquees = new ArrayList<>();

    public List<PromotionDTO> getPromotionsAppliquees() {
        return promotionsAppliquees;
    }

    public void setPromotionsAppliquees(List<PromotionDTO> promotionsAppliquees) {
        this.promotionsAppliquees = promotionsAppliquees;
    }

    public List<PromotionCadeauInfo> getPromotionsCadeaux() {
        return promotionsCadeaux;
    }

    public void setPromotionsCadeaux(List<PromotionCadeauInfo> promotionsCadeaux) {
        this.promotionsCadeaux = promotionsCadeaux;
    }

    public List<String> getProduitsOffertsNoms() {
        return produitsOffertsNoms;
    }

    public void setProduitsOffertsNoms(List<String> produitsOffertsNoms) {
        this.produitsOffertsNoms = produitsOffertsNoms;
    }
// --- Constructors ---

    // Constructeur vide (Good to have for Jackson)
    public CommandeDTO() {}

    // Constructeur complet avec tous les champs (Updated to include promotionIds)
    public CommandeDTO(Long id, LocalDate dateCreation, StatutCommande statut,
                       Long clientId, Long vendeurId, Long approuveParId,
                       String vendeurNom, String clientNom, String approuveParNom,
                       List<LigneCommandeDTO> lignes, LocalDate dateLivraison,
                       BigDecimal montantReduction, BigDecimal montantTotal,
                       BigDecimal montantTotalAvantRemise, List<Long> promotionIds) {
        this.id = id;
        this.dateCreation = dateCreation;
        this.statut = statut;
        this.clientId = clientId;
        this.vendeurId = vendeurId;
        this.approuveParId = approuveParId;
        this.vendeurNom = vendeurNom;
        this.clientNom = clientNom;
        this.approuveParNom = approuveParNom;
        this.lignes = lignes;
        this.dateLivraison = dateLivraison;
        this.montantReduction = montantReduction;
        this.montantTotal = montantTotal;
        this.montantTotalAvantRemise = montantTotalAvantRemise;
        this.promotionIds = promotionIds; // Now included in the constructor
    }

    // --- Getters & Setters (Organized for better readability) ---

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public LocalDate getDateCreation() { return dateCreation; }
    public void setDateCreation(LocalDate dateCreation) { this.dateCreation = dateCreation; }

    public StatutCommande getStatut() { return statut; }
    public void setStatut(StatutCommande statut) { this.statut = statut; }

    public Long getClientId() { return clientId; }
    public void setClientId(Long clientId) { this.clientId = clientId; }

    public Long getVendeurId() { return vendeurId; }
    public void setVendeurId(Long vendeurId) { this.vendeurId = vendeurId; }

    public Long getApprouveParId() { return approuveParId; }
    public void setApprouveParId(Long approuveParId) { this.approuveParId = approuveParId; }

    public String getVendeurNom() { return vendeurNom; }
    public void setVendeurNom(String vendeurNom) { this.vendeurNom = vendeurNom; }

    public String getClientNom() { return clientNom; }
    public void setClientNom(String clientNom) { this.clientNom = clientNom; }

    public String getApprouveParNom() { return approuveParNom; }
    public void setApprouveParNom(String approuveParNom) { this.approuveParNom = approuveParNom; }

    public List<LigneCommandeDTO> getLignes() { return lignes; }
    public void setLignes(List<LigneCommandeDTO> lignes) { this.lignes = lignes; }

    public LocalDate getDateLivraison() { return dateLivraison; }
    public void setDateLivraison(LocalDate dateLivraison) { this.dateLivraison = dateLivraison; }

    public BigDecimal getMontantReduction() { return montantReduction; }
    public void setMontantReduction(BigDecimal montantReduction) { this.montantReduction = montantReduction; }

    public BigDecimal getMontantTotal() { return montantTotal; }
    public void setMontantTotal(BigDecimal montantTotal) { this.montantTotal = montantTotal; }

    public BigDecimal getMontantTotalAvantRemise() { return montantTotalAvantRemise; }
    public void setMontantTotalAvantRemise(BigDecimal montantTotalAvantRemise) { this.montantTotalAvantRemise = montantTotalAvantRemise; }

    // Corrected placement for promotionIds getters/setters
    public List<Long> getPromotionIds() { return promotionIds; }
    public void setPromotionIds(List<Long> promotionIds) { this.promotionIds = promotionIds; }
}