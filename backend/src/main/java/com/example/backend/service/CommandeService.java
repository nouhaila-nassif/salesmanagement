package com.example.backend.service;

import com.example.backend.dto.CommandeDTO;
import com.example.backend.entity.*;
import com.example.backend.repository.*;
import jakarta.transaction.Transactional;
import org.jetbrains.annotations.NotNull;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class CommandeService {

    @Autowired
    private PromotionRepository promotionRepository;
    @Autowired
    private CommandeRepository commandeRepository;
    @Autowired
    private StockCamionRepository stockCamionRepository;
    @Autowired
    private UtilisateurRepository utilisateurRepository;

    @Autowired
    private StockCamionService stockCamionService;
    @Autowired
    private ProduitRepository produitRepository;
    @Autowired
    private UtilisateurService utilisateurService;
    private Utilisateur getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return utilisateurService.findByNomUtilisateur(auth.getName());
    }
    public String genererContexteCommandes() {
        Utilisateur utilisateur = getCurrentUser(); // Récupère l'utilisateur connecté

        List<Commande> commandes;

        switch (utilisateur.getRole()) {
            case "SUPERVISEUR":
                List<Utilisateur> tousLesUtilisateurs = utilisateurRepository.findAll();

                List<Long> vendeurIds = tousLesUtilisateurs.stream()
                        .filter(u -> (u instanceof VendeurDirect || u instanceof PreVendeur))
                        .filter(u -> {
                            if (u instanceof VendeurDirect vd) {
                                return vd.getSuperviseur() != null && vd.getSuperviseur().getId().equals(utilisateur.getId());
                            } else if (u instanceof PreVendeur pv) {
                                return pv.getSuperviseur() != null && pv.getSuperviseur().getId().equals(utilisateur.getId());
                            }
                            return false;
                        })
                        .map(Utilisateur::getId)
                        .collect(Collectors.toList());

                commandes = commandeRepository.findByVendeurIdIn(vendeurIds);
                break;

            case "ADMIN":
                commandes = commandeRepository.findAll();
                break;

            case "VENDEURDIRECT":
            case "PREVENDEUR":
                commandes = commandeRepository.findByVendeurId(utilisateur.getId());
                break;

            default:
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Accès non autorisé");
        }

        if (commandes.isEmpty()) return "Aucune commande trouvée.";

        StringBuilder contexte = new StringBuilder("Historique des commandes :\n");

        for (Commande cmd : commandes) {
            if (cmd.getClient() == null || cmd.getLignes() == null || cmd.getLignes().isEmpty()) continue;

            Long idCommande = cmd.getId();
            String clientNom = cmd.getClient().getNom();
            String date = cmd.getDateCreation() != null ? cmd.getDateCreation().toString() : "Date inconnue";
            String montant = cmd.getMontantTotal() != null ? String.format("%.2f DH", cmd.getMontantTotal()) : "Montant inconnu";
            String statut = cmd.getStatut() != null ? cmd.getStatut().name() : "Statut inconnu";

            String produits = cmd.getLignes().stream()
                    .map(ligne -> {
                        String nomProduit = ligne.getProduit() != null ? ligne.getProduit().getNom() : "Produit inconnu";
                        return nomProduit + " x" + ligne.getQuantite();
                    })
                    .collect(Collectors.joining(", "));

            contexte.append("- [ID: ").append(idCommande).append("] ")
                    .append(clientNom)
                    .append(" | Date : ").append(date)
                    .append(" | Produits : ").append(produits)
                    .append(" | Total : ").append(montant)
                    .append(" | ✅ Statut : ").append(statut)
                    .append("\n");
        }

        return contexte.toString();
    }

    public Commande getCommandeById(Long id) {
        return commandeRepository.findById(id).orElse(null);
    }

    public void changerStatut(Long id, String nouveauStatut) {
        Commande commande = commandeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Commande non trouvée"));

        commande.setStatut(StatutCommande.valueOf(nouveauStatut));
        commandeRepository.save(commande);
    }



// 2. CORRECTION : Méthode creerCommande avec debug détaillé

    @Transactional
    public Commande creerCommande(@NotNull Commande commande, Utilisateur user) {
        System.out.println("=== DÉBUT CRÉATION COMMANDE ===");

        commande.setDateCreation(LocalDate.now());
        commande.setStatut(StatutCommande.EN_ATTENTE);
        commande.setVendeur(user);

        BigDecimal montantAvantRemise = BigDecimal.ZERO;
        BigDecimal montantReduction = BigDecimal.ZERO;

        Set<Promotion> promotionsAppliquees = new HashSet<>();
        List<LigneCommande> lignesCadeaux = new ArrayList<>();

        for (LigneCommande ligne : commande.getLignes()) {
            ligne.setCommande(commande);

            Produit produit = produitRepository.findByIdWithPromotions(ligne.getProduit().getId())
                    .orElseThrow(() -> new RuntimeException("Produit non trouvé"));

            BigDecimal prix = BigDecimal.valueOf(produit.getPrixUnitaire());
            BigDecimal quantite = BigDecimal.valueOf(ligne.getQuantite());
            BigDecimal sousTotal = prix.multiply(quantite);
            montantAvantRemise = montantAvantRemise.add(sousTotal);

            Set<Promotion> promotionsProduit = produit.getPromotions();
            Set<Promotion> promotionsCategorie = new HashSet<>();
            if (produit.getCategorie() != null) {
                List<Promotion> promotionsList = promotionRepository.findByCategorie(produit.getCategorie());
                promotionsCategorie.addAll(promotionsList);
            }

            Set<Promotion> toutesPromotions = new HashSet<>();
            if (promotionsProduit != null) toutesPromotions.addAll(promotionsProduit);
            toutesPromotions.addAll(promotionsCategorie);

            for (Promotion promo : toutesPromotions) {
                System.out.println(">>> Test de la promotion : " + promo.getNom());

                if (!promo.estApplicable(produit, ligne.getQuantite())) {
                    System.out.println("⛔ Non applicable : produit=" + produit.getId() + " | date=" + LocalDate.now() + " | promo=" + promo.getId());
                    continue;
                }

                if (promo.getType() == TypePromotion.CADEAU) {
                    Produit produitOffert = promo.getProduitOffert();
                    if (produitOffert == null && promo.getProduitOffert() != null) {
                        produitOffert = produitRepository.findByNom(promo.getProduitOffert().getNom())
                                .orElseThrow(() -> new RuntimeException("Produit offert introuvable pour la promotion " + promo.getId()));
                    }

                    int nbCadeaux = (int) (ligne.getQuantite() / promo.getQuantiteCondition()) * promo.getQuantiteOfferte();

                    if (nbCadeaux > 0) {
                        LigneCommande ligneCadeau = new LigneCommande();
                        ligneCadeau.setProduit(produitOffert);
                        ligneCadeau.setQuantite(nbCadeaux);
                        ligneCadeau.setPrixUnitaire(0.0f);
                        ligneCadeau.setCommande(commande);

                        lignesCadeaux.add(ligneCadeau);
                        promotionsAppliquees.add(promo);

                        System.out.println("🎁 Cadeau ajouté : " + produitOffert.getNom() + " x" + nbCadeaux);
                    }

                    continue;
                }

                // Autres promotions (réduction)
                BigDecimal reduction = promo.calculerReduction(sousTotal, ligne.getQuantite());
                montantReduction = montantReduction.add(reduction);
                promotionsAppliquees.add(promo);

                System.out.println("✅ Promotion appliquée : " + promo.getNom() + " => réduction : " + reduction);
            }
        }

        // Ajout des cadeaux à la commande après la boucle
        commande.getLignes().addAll(lignesCadeaux);

        commande.setMontantTotalAvantRemise(montantAvantRemise);
        commande.setMontantReduction(montantReduction);

        BigDecimal montantFinal = montantAvantRemise.subtract(montantReduction);
        if (montantFinal.compareTo(BigDecimal.ZERO) < 0) montantFinal = BigDecimal.ZERO;
        commande.setMontantTotal(montantFinal);

        commande.setPromotions(promotionsAppliquees);

        Commande savedCommande = commandeRepository.save(commande);

        System.out.println("=== FIN CRÉATION COMMANDE ===");
        return savedCommande;
    }


    private Set<Promotion> getPromotionsApplicables(Commande commande) {
        LocalDate today = LocalDate.now();
        List<Promotion> toutesPromotions = promotionRepository.findAll();

        Set<Promotion> applicables = new HashSet<>();
        for (Promotion promo : toutesPromotions) {
            if (promo.getDateDebut() != null && promo.getDateFin() != null) {
                if (today.isBefore(promo.getDateDebut()) || today.isAfter(promo.getDateFin())) {
                    continue;
                }
            }
            System.out.println("Promotion applicable trouvée: " + promo);
            applicables.add(promo);
        }
        System.out.println("Total promotions applicables: " + applicables.size());
        return applicables;
    }


    /**
     * Récupérer toutes les commandes.
     */
    public List<Commande> getAllCommandes() {
        return commandeRepository.findAll();
    }



    /**
     * Récupérer les commandes pour un Superviseur.
     */
    public List<Commande> getCommandesForSupervisor(Utilisateur user) {
        if (user instanceof Superviseur) {
            List<Long> vendeurIds = user.getRoutes().stream()
                    .flatMap(route -> route.getVendeurs().stream())
                    .map(Utilisateur::getId)
                    .collect(Collectors.toList());
            return commandeRepository.findByVendeurIdIn(vendeurIds);
        }
        throw new RuntimeException("Droits insuffisants.");
    }



    private Commande convertToEntity(CommandeDTO dto, Commande existing) {
        if (dto.getDateLivraison() != null) {
            existing.setDateLivraison(dto.getDateLivraison());
        }

        if (dto.getDateCreation() != null) {
            existing.setDateCreation(dto.getDateCreation());
        }

        if (dto.getStatut() != null) {
            existing.setStatut(dto.getStatut());
        }

        if (dto.getClientId() != null) {
            Client client = new Client();
            client.setId(dto.getClientId());
            existing.setClient(client);
        }

        if (dto.getVendeurId() != null) {
            Utilisateur vendeur = new Vendeur();
            vendeur.setId(dto.getVendeurId());
            existing.setVendeur(vendeur);
        }

        if (dto.getApprouveParId() != null) {
            Utilisateur approuvePar = new Vendeur();
            approuvePar.setId(dto.getApprouveParId());
            existing.setApprouvePar(approuvePar);
        }

        if (dto.getLignes() != null) {
            List<LigneCommande> lignes = dto.getLignes().stream().map(ligneDto -> {
                LigneCommande ligne = new LigneCommande();
                ligne.setId(ligneDto.getId());
                ligne.setQuantite(ligneDto.getQuantite());

                Produit produit = new Produit();
                produit.setId(ligneDto.getProduitId());
                ligne.setProduit(produit);

                ligne.setCommande(existing);
                return ligne;
            }).collect(Collectors.toList());

            existing.getLignes().clear();
            existing.getLignes().addAll(lignes);
        }

        return existing;
    }

    public Commande modifierCommande(Long id, CommandeDTO dto, Utilisateur currentUser) {
        Commande existing = commandeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Commande introuvable"));

        // Convertir DTO vers entity existante
        Commande updated = convertToEntity(dto, existing);

        // Recalculer montants selon logique métier
        recalculeMontants(updated);

        // Sauvegarder et retourner
        return commandeRepository.save(updated);
    }

    private void recalculeMontants(Commande commande) {
        BigDecimal montantAvantRemise = BigDecimal.ZERO;
        BigDecimal totalReductions = BigDecimal.ZERO;

        Set<Promotion> promotions = getPromotionsApplicables(commande); // ta méthode pour récupérer promos

        if (commande.getLignes() != null) {
            for (LigneCommande ligne : commande.getLignes()) {
                Produit produitOriginal = produitRepository.findById(ligne.getProduit().getId())
                        .orElseThrow(() -> new RuntimeException("Produit non trouvé avec l'id : " + ligne.getProduit().getId()));

                BigDecimal prixInitial = BigDecimal.valueOf(produitOriginal.getPrixUnitaire()).setScale(2, RoundingMode.HALF_UP);
                int quantite = ligne.getQuantite();

                BigDecimal montantLigne = prixInitial.multiply(BigDecimal.valueOf(quantite));
                montantAvantRemise = montantAvantRemise.add(montantLigne);

                BigDecimal reductionLigne = BigDecimal.ZERO;
                BigDecimal prixReduitUnitaire = prixInitial;

                for (Promotion promo : promotions) {
                    BigDecimal reduction = promo.calculerReduction(prixReduitUnitaire, quantite);
                    if (reduction != null && reduction.compareTo(BigDecimal.ZERO) > 0) {
                        BigDecimal maxReductionPossible = prixReduitUnitaire.multiply(BigDecimal.valueOf(quantite)).subtract(reductionLigne);
                        if (reduction.compareTo(maxReductionPossible) > 0) {
                            reduction = maxReductionPossible;
                        }

                        reductionLigne = reductionLigne.add(reduction);

                        BigDecimal reductionParUnite = reduction.divide(BigDecimal.valueOf(quantite), 6, RoundingMode.HALF_UP);
                        prixReduitUnitaire = prixReduitUnitaire.subtract(reductionParUnite);

                        if (prixReduitUnitaire.compareTo(BigDecimal.ZERO) < 0) {
                            prixReduitUnitaire = BigDecimal.ZERO;
                        }
                    }
                }

                totalReductions = totalReductions.add(reductionLigne);

                // Mise à jour produit dans la ligne avec prix réduit (optionnel)
                Produit produitPourLigne = new Produit();
                produitPourLigne.setId(produitOriginal.getId());
                produitPourLigne.setNom(produitOriginal.getNom());
                produitPourLigne.setDescription(produitOriginal.getDescription());
                produitPourLigne.setMarque(produitOriginal.getMarque());
                produitPourLigne.setPrixUnitaire(prixReduitUnitaire.floatValue());
                produitPourLigne.setCategorie(produitOriginal.getCategorie());
                produitPourLigne.setImageUrl(produitOriginal.getImageUrl());

                ligne.setProduit(produitPourLigne);
                ligne.setCommande(commande);
            }
        }

        commande.setMontantTotalAvantRemise(montantAvantRemise);

        BigDecimal montantFinal = montantAvantRemise.subtract(totalReductions);
        if (montantFinal.compareTo(BigDecimal.ZERO) < 0) {
            montantFinal = BigDecimal.ZERO;
        }

        commande.setMontantTotal(montantFinal);
        commande.setMontantReduction(totalReductions);
    }

    /**
     * Annuler une commande selon les droits de l'utilisateur.
     */
    @Transactional
    public void annulerCommande(Long commandeId, Utilisateur user) {
        Commande commande = commandeRepository.findById(commandeId)
                .orElseThrow(() -> new RuntimeException("Commande non trouvée."));

        if (commande.getStatut() == StatutCommande.ANNULEE) {
            throw new RuntimeException("La commande est déjà annulée.");
        }

        if (commande.getStatut() == StatutCommande.VALIDEE) {
            throw new RuntimeException("Impossible d'annuler une commande déjà approuvée.");
        }

        // Si utilisateur est VendeurDirect, incrémenter le stock
        if (user instanceof VendeurDirect) {
            StockCamion stock = stockCamionRepository.findByChauffeur((VendeurDirect) user)
                    .orElseThrow(() -> new RuntimeException("Aucun stock trouvé pour ce vendeur."));

            for (LigneCommande ligne : commande.getLignes()) {
                stockCamionService.incrementerStock(ligne.getProduit().getId(), ligne.getQuantite());
                System.out.println("Stock ré-incrémenté pour le produit : " + ligne.getProduit().getNom()
                        + ", quantité : " + ligne.getQuantite());
            }
        }

        // Changer le statut de la commande
        commande.setStatut(StatutCommande.ANNULEE);
        commandeRepository.save(commande);

        System.out.println("Commande " + commandeId + " annulée.");
    }

    @Transactional
    public void supprimerCommande(Long commandeId, Utilisateur user) {
        Commande commande = commandeRepository.findById(commandeId)
                .orElseThrow(() -> new RuntimeException("Commande non trouvée."));

        // Si utilisateur est VendeurDirect, incrémenter le stock avant suppression
        if (user instanceof VendeurDirect) {
            StockCamion stock = stockCamionRepository.findByChauffeur((VendeurDirect) user)
                    .orElseThrow(() -> new RuntimeException("Aucun stock trouvé pour ce vendeur."));

            for (LigneCommande ligne : commande.getLignes()) {
                stockCamionService.incrementerStock(ligne.getProduit().getId(), ligne.getQuantite());
                System.out.println("Stock ré-incrémenté pour le produit : " + ligne.getProduit().getNom()
                        + ", quantité : " + ligne.getQuantite());
            }
        }

        commandeRepository.delete(commande);
        System.out.println("Commande " + commandeId + " supprimée.");
    }


    /**
     * Approuver une commande (Superviseur, ResponsableUnite, etc.).
     */
    public void approuverCommande(Long id, Utilisateur utilisateur) {
        Commande commande = commandeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Commande introuvable avec l'id : " + id));

        if (!(utilisateur instanceof Administrateur
                || utilisateur instanceof PreVendeur
                || utilisateur instanceof VendeurDirect
                || utilisateur instanceof Superviseur)) {
            throw new RuntimeException("Accès refusé : vous n'êtes pas autorisé à approuver une commande.");
        }

        commande.setStatut(StatutCommande.VALIDEE);
        commande.setApprouvePar(utilisateur);

        commandeRepository.save(commande);
    }

    /**
     * Supprimer une commande (Administrateur uniquement).
     */


}
