package com.example.backend.controller;

import com.example.backend.dto.*;
import com.example.backend.entity.*;
import com.example.backend.repository.*;
import com.example.backend.service.ClientService;
import com.example.backend.service.CommandeService;
import com.example.backend.service.PromotionService;
import com.example.backend.service.UtilisateurService; // Removed PromotionService import as it's not used in Controller
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/commandes")
public class CommandeController {
    @Autowired
    private CommandeRepository commandeRepository;
    @Autowired
    private PromotionService promotionService;
    @Autowired
    private CommandeService commandeService;
    private final ProduitRepository produitRepository;
    private final PromotionRepository promotionRepository;
    @Autowired
    private UtilisateurService utilisateurService;
    @Autowired
    private ClientRepository clientRepository;
    @Autowired
    private UtilisateurRepository utilisateurRepository;
    // Removed the unused 'private PromotionService promotionService;' field
    // as it's not autowired or used in this controller.

    @Autowired
    public CommandeController(CommandeService commandeService,
                              ClientRepository clientRepository,
                              ProduitRepository produitRepository,
                              PromotionRepository promotionRepository) {
        this.commandeService = commandeService;
        this.produitRepository = produitRepository;
        this.promotionRepository = promotionRepository;
    }
    @PostMapping("/{id}/cancel")
    public ResponseEntity<?> cancelCommande(@PathVariable Long id) {
        Utilisateur currentUser = getCurrentUser();

        if (currentUser instanceof PreVendeur || currentUser instanceof VendeurDirect || currentUser instanceof Administrateur) {
            commandeService.annulerCommande(id, currentUser);
            return ResponseEntity.ok().build();
        }

        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body("Accès refusé : vous ne pouvez pas annuler cette commande.");
    }

    private Utilisateur getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return utilisateurService.findByNomUtilisateur(auth.getName());
    }
    @GetMapping
    public List<CommandeDTO> getAllCommandes() {
        Utilisateur utilisateur = getCurrentUser(); // récupère l'utilisateur connecté

        List<Commande> commandes;

        switch (utilisateur.getRole()) {
            case "SUPERVISEUR":
                // Récupérer tous les utilisateurs supervisés
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

        // Pour chaque commande, on enrichit les produits de leurs promotions avant de convertir en DTO
        return commandes.stream()
                .map(commande -> {
                    // On enrichit chaque produit dans les lignes avec ses promotions
                    commande.getLignes().forEach(ligne -> {
                        Produit produit = ligne.getProduit();
                        if (produit != null) {
                            List<Promotion> promos = promotionService.getPromotionsByProduitId(produit.getId());
                            produit.setPromotions(new HashSet<>(promos));  // convertit List -> Set
                        }
                    });
                    return convertToDTO(commande);
                })
                .collect(Collectors.toList());
    }

    @PutMapping("/{id}")
    public ResponseEntity<CommandeDTO> updateCommande(@PathVariable Long id, @RequestBody CommandeDTO commandeDTO) {
        Utilisateur currentUser = getCurrentUser();

        if (currentUser instanceof Vendeur || currentUser instanceof Administrateur) {
            Commande updatedCommande = commandeService.modifierCommande(id, commandeDTO, currentUser);
            return ResponseEntity.ok(convertToDTO(updatedCommande));
        }

        return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
    }

    @PostMapping(value = "/create", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> createCommande(@RequestBody CommandeDTO commandeDTO) {
        Utilisateur currentUser = getCurrentUser();

        if (!(currentUser instanceof Vendeur || currentUser instanceof Administrateur)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Droits insuffisants pour créer une commande.");
        }

        try {
            Commande commande = new Commande();
            commande.setDateLivraison(commandeDTO.getDateLivraison());

            // Client
            if (commandeDTO.getClientId() != null) {
                Client client = clientRepository.findById(commandeDTO.getClientId())
                        .orElseThrow(() -> new RuntimeException("Client non trouvé"));
                commande.setClient(client);
            }

            // Lignes de commande (hors cadeaux)
            List<LigneCommande> lignes = new ArrayList<>();
            for (LigneCommandeDTO ligneDTO : commandeDTO.getLignes()) {
                Produit produit = produitRepository.findById(ligneDTO.getProduitId())
                        .orElseThrow(() -> new RuntimeException("Produit non trouvé : ID = " + ligneDTO.getProduitId()));

                LigneCommande ligne = new LigneCommande();
                ligne.setProduit(produit);
                ligne.setQuantite(ligneDTO.getQuantite());
                ligne.setProduitOffert(false); // très important pour éviter les erreurs boolean
                ligne.setCommande(commande);

                lignes.add(ligne);
            }
            commande.setLignes(lignes);

            // Appel du service métier pour gestion complète (calcul montant, promos, cadeaux…)
            Commande savedCommande = commandeService.creerCommande(commande, currentUser);

            // DTO réponse
            CommandeDTO result = convertToDTO(savedCommande);
            return ResponseEntity.ok(result);

        } catch (RuntimeException e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body("Erreur: " + e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Erreur interne: " + e.getMessage());
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<CommandeDTO> getCommandeById(@PathVariable Long id) {
        Commande commande = commandeService.getCommandeById(id);
        if (commande == null) {
            return ResponseEntity.notFound().build();
        }

        // Avant conversion en DTO, charger les promotions des produits dans chaque ligne
        commande.getLignes().forEach(ligne -> {
            Produit produit = ligne.getProduit();
            if (produit != null) {
                // Récupérer les promotions liées au produit (adapter selon ta méthode)
                List<Promotion> promosList = promotionService.getPromotionsByProduitId(produit.getId());
                Set<Promotion> promosSet = new HashSet<>(promosList);
                produit.setPromotions(promosSet);
            }
        });

        CommandeDTO dto = convertToDTO(commande);
        return ResponseEntity.ok(dto);
    }

    @PutMapping("/{id}/changer-statut")
    public ResponseEntity<Void> changerStatutCommande(
            @PathVariable Long id,
            @RequestParam String nouveauStatut) {
        commandeService.changerStatut(id, nouveauStatut);
        return ResponseEntity.ok().build();
    }


    @PutMapping("/{id}/marquer-livree")
    public ResponseEntity<Void> marquerCommandeCommeLivree(@PathVariable Long id) {
        commandeService.changerStatut(id, "LIVREE");
        return ResponseEntity.ok().build();
    }

    // --- CRUCIAL FIX HERE: Populate promotionIds in CommandeDTO ---


    public CommandeDTO convertToDTO(Commande commande) {
        CommandeDTO dto = new CommandeDTO();

        // Mapping des propriétés de base
        dto.setId(commande.getId());
        dto.setDateCreation(commande.getDateCreation());
        dto.setDateLivraison(commande.getDateLivraison());
        dto.setStatut(commande.getStatut());
        dto.setPromotionsAppliquees(
                commande.getPromotions().stream()
                        .map(PromotionDTO::new)
                        .collect(Collectors.toList())
        );

        // Gestion des promotions
        processPromotions(commande, dto);

        // Mapping des relations
        mapClientInfo(commande, dto);
        mapVendeurInfo(commande, dto);
        mapApprouveurInfo(commande, dto);

        // Gestion des lignes de commande
        processLignesCommande(commande, dto);

        // Mapping des montants avec valeurs par défaut
        mapMontants(commande, dto);

        return dto;
    }

    // Méthodes auxiliaires décomposées
    private void processPromotions(Commande commande, CommandeDTO dto) {

        Set<PromotionCadeauInfo> promotionsCadeaux = new HashSet<>();
        List<Long> promotionIds = new ArrayList<>();

        // 1. Traiter les promotions déjà associées
        if (commande.getPromotions() != null && !commande.getPromotions().isEmpty()) {
            commande.getPromotions().forEach(promotion -> {
                promotionIds.add(promotion.getId());

                if (promotion.getType() == TypePromotion.CADEAU) {
                    ajouterPromotionCadeau(promotion, promotionsCadeaux);
                }
            });
        }

        // 2. Rechercher les promotions cadeaux applicables (non encore associées)
        List<Promotion> promotionsCadeauxDisponibles = promotionRepository
                .findByTypeAndDateDebutLessThanEqualAndDateFinGreaterThanEqual(
                        TypePromotion.CADEAU,
                        LocalDate.now(),
                        LocalDate.now()
                );

        for (Promotion promotionCadeau : promotionsCadeauxDisponibles) {
            // Vérifier si elle n'est pas déjà associée
            if (!promotionIds.contains(promotionCadeau.getId()) &&
                    isPromotionCadeauApplicable(commande, promotionCadeau)) {


                promotionIds.add(promotionCadeau.getId());
                ajouterPromotionCadeau(promotionCadeau, promotionsCadeaux);
            }
        }

        dto.setPromotionIds(promotionIds);
        dto.setPromotionsCadeaux(new ArrayList<>(promotionsCadeaux));
    }

    private void ajouterPromotionCadeau(Promotion promotion, Set<PromotionCadeauInfo> promotionsCadeaux) {
        PromotionCadeauInfo info = new PromotionCadeauInfo();
        info.setPromotionId(promotion.getId());

        if (promotion.getProduitOffert() != null) {
            info.setProduitOffertNom(promotion.getProduitOffert().getNom());
        }

        info.setQuantite(promotion.getQuantiteOfferte() != null ?
                promotion.getQuantiteOfferte() : 0);

        if (promotion.getProduitCondition() != null) {
            info.setProduitConditionNom(promotion.getProduitCondition().getNom());
            info.setQuantiteCondition(promotion.getQuantiteCondition());
        }

        promotionsCadeaux.add(info);
    }

    private boolean


    isPromotionCadeauApplicable(Commande commande, Promotion promotion) {
        // Vérifier si la commande remplit les conditions pour cette promotion cadeau
        if (promotion.getProduitCondition() != null) {
            String produitConditionNom = promotion.getProduitCondition().getNom();
            Integer quantiteRequise = promotion.getQuantiteCondition();

            int quantiteTotale = commande.getLignes().stream()
                    .filter(ligne -> ligne.getProduit().getNom().equals(produitConditionNom))
                    .mapToInt(LigneCommande::getQuantite)
                    .sum();

            boolean applicable = quantiteTotale >= quantiteRequise;

            return applicable;
        }
        return true;
    }
    private void processLignesCommande(Commande commande, CommandeDTO dto) {
        if (commande.getLignes() == null || commande.getLignes().isEmpty()) {
            dto.setLignes(Collections.emptyList());
            return;
        }

        // Créer la map des quantités offertes APRÈS avoir traité les promotions
        Map<String, Integer> quantitesOffertesRestantes = dto.getPromotionsCadeaux().stream()
                .collect(Collectors.toMap(
                        PromotionCadeauInfo::getProduitOffertNom,
                        PromotionCadeauInfo::getQuantite,  // Corriger ici aussi
                        Integer::sum));

        List<LigneCommandeDTO> ligneDTOs = commande.getLignes().stream()
                .map(ligne -> convertLigneToDTO(ligne, quantitesOffertesRestantes))
                .collect(Collectors.toList());

        dto.setLignes(ligneDTOs);
    }

    private LigneCommandeDTO convertLigneToDTO(LigneCommande ligne, Map<String, Integer> quantitesOffertesRestantes) {
        LigneCommandeDTO ligneDTO = new LigneCommandeDTO();
        ligneDTO.setId(ligne.getId());
        ligneDTO.setQuantite(ligne.getQuantite());

        boolean isOffert = false;
        if (ligne.getProduit() != null) {
            String nomProduit = ligne.getProduit().getNom();
            Integer qRestante = quantitesOffertesRestantes.get(nomProduit);

            if (qRestante != null && qRestante >= ligne.getQuantite()) {
                isOffert = true;
                quantitesOffertesRestantes.put(nomProduit, qRestante - ligne.getQuantite());
            }
        }
        ligneDTO.setProduitOffert(isOffert);

        if (ligne.getProduit() != null) {
            ligneDTO.setProduitId(ligne.getProduit().getId());
            ligneDTO.setProduit(convertProductToDTO(ligne));
        }

        return ligneDTO;
    }
    private ProductDTO convertProductToDTO(LigneCommande ligne) {
        Produit produit = ligne.getProduit();
        ProductDTO produitDTO = new ProductDTO();

        produitDTO.setNom(produit.getNom());
        produitDTO.setDescription(produit.getDescription());
        produitDTO.setMarque(produit.getMarque());

        Float prixUnitaire = ligne.getPrixUnitaire() != null ?
                ligne.getPrixUnitaire() : produit.getPrixUnitaire();
        produitDTO.setPrixUnitaire(prixUnitaire != null ? prixUnitaire.doubleValue() : 0d);

        produitDTO.setImageUrl(produit.getImageUrl());

        if (produit.getCategorie() != null) {
            produitDTO.setCategorieId(produit.getCategorie().getId());
        }

        if (produit.getPromotions() != null && !produit.getPromotions().isEmpty()) {
            produitDTO.setPromotion(new PromotionDTO(produit.getPromotions().iterator().next()));
        }

        return produitDTO;
    }

    private void mapClientInfo(Commande commande, CommandeDTO dto) {
        if (commande.getClient() != null) {
            dto.setClientId(commande.getClient().getId());
            dto.setClientNom(commande.getClient().getNom());
        }
    }

    private void mapVendeurInfo(Commande commande, CommandeDTO dto) {
        if (commande.getVendeur() != null) {
            dto.setVendeurId(commande.getVendeur().getId());
            dto.setVendeurNom(commande.getVendeur().getNomUtilisateur());
        }
    }

    private void mapApprouveurInfo(Commande commande, CommandeDTO dto) {
        if (commande.getApprouvePar() != null) {
            dto.setApprouveParId(commande.getApprouvePar().getId());
            dto.setApprouveParNom(commande.getApprouvePar().getNomUtilisateur());
        }
    }

    private void mapMontants(Commande commande, CommandeDTO dto) {
        dto.setMontantReduction(commande.getMontantReduction() != null ?
                commande.getMontantReduction() : BigDecimal.ZERO);
        dto.setMontantTotal(commande.getMontantTotal() != null ?
                commande.getMontantTotal() : BigDecimal.ZERO);
        dto.setMontantTotalAvantRemise(commande.getMontantTotalAvantRemise() != null ?
                commande.getMontantTotalAvantRemise() : BigDecimal.ZERO);
    }
    @PostMapping("/{id}/approve")
    public ResponseEntity<?> approveCommande(@PathVariable Long id) {
        Utilisateur currentUser = getCurrentUser();

        if (currentUser instanceof Superviseur || currentUser instanceof ResponsableUnite || currentUser instanceof Administrateur) {
            commandeService.approuverCommande(id, currentUser);
            return ResponseEntity.ok().build();
        }

        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body("Accès refusé : vous ne pouvez pas approuver cette commande.");
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteCommande(@PathVariable Long id) {
        Utilisateur currentUser = getCurrentUser();

        // Suppression sans vérifier le rôle
        commandeService.supprimerCommande(id, currentUser);
        return ResponseEntity.ok().build();
    }

    // === Méthodes de conversion DTO <-> Entité ===
    private Commande convertToEntity(CommandeDTO dto) {
        Commande commande = new Commande();

        if (dto.getId() != null) {
            commande.setId(dto.getId());
        }
        if (dto.getDateLivraison() != null) {
            commande.setDateLivraison(dto.getDateLivraison());
        }
        if (dto.getDateCreation() != null) {
            commande.setDateCreation(dto.getDateCreation());
        }
        if (dto.getStatut() != null) {
            commande.setStatut(dto.getStatut());
        }

        // Client (using ID)
        if (dto.getClientId() != null) {
            Client client = new Client();
            client.setId(dto.getClientId());
            commande.setClient(client);
        }

        // Vendeur (using ID)
        if (dto.getVendeurId() != null) {
            Utilisateur vendeur = new Vendeur();
            vendeur.setId(dto.getVendeurId());
            commande.setVendeur(vendeur);
        }

        // Approuvé par (using ID)
        if (dto.getApprouveParId() != null) {
            Utilisateur approuvePar = new Vendeur();
            approuvePar.setId(dto.getApprouveParId());
            commande.setApprouvePar(approuvePar);
        }

        // Lignes de commande
        if (dto.getLignes() != null) {
            List<LigneCommande> lignes = dto.getLignes().stream().map(ligneDto -> {
                LigneCommande ligne = new LigneCommande();
                ligne.setId(ligneDto.getId());
                ligne.setQuantite(ligneDto.getQuantite());

                Produit produit = new Produit();
                produit.setId(ligneDto.getProduitId());
                ligne.setProduit(produit);

                ligne.setCommande(commande);
                return ligne;
            }).collect(Collectors.toList());

            commande.setLignes(lignes);
        }

        return commande;
    }
}