package com.example.backend.controller;

import com.example.backend.dto.ProductDTO;
import com.example.backend.dto.ProduitResponseDTO;
import com.example.backend.dto.ProduitUpdateDTO;
import com.example.backend.dto.PromotionDTO;
import com.example.backend.entity.*;
import com.example.backend.repository.CatégorieProduitRepository;
import com.example.backend.repository.ProduitRepository;
import com.example.backend.repository.PromotionRepository;
import com.example.backend.repository.UtilisateurRepository;
import com.example.backend.security.CustomUserDetailsService;
import com.example.backend.service.CatégorieProduitService;
import com.example.backend.service.ProduitService;
import com.example.backend.service.UtilisateurService;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.*;

@RestController
@RequestMapping("/api/produits")
public class ProduitController {
    @Autowired
    private ProduitRepository produitRepository;
    @Autowired
    private UtilisateurRepository utilisateurRepository;

    @Autowired
    private ProduitService produitService;
    @Autowired
    private CatégorieProduitService categorieService;
    @Autowired
    private CatégorieProduitRepository categorieProduitRepository;

    @Autowired
    private UtilisateurService utilisateurService;

    private Utilisateur getCurrentAdmin() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        Utilisateur utilisateur = utilisateurService.findByNomUtilisateur(username);
        if (!(utilisateur instanceof Administrateur)) {
            throw new RuntimeException("Accès refusé : seul un administrateur peut gérer les produits.");
        }
        return utilisateur;
    }

    @PostMapping(value = "/create", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Produit> createProduit(@RequestBody ProductDTO productDTO) {
        getCurrentAdmin(); // Vérification d'authentification ou contexte d'admin

        // Conversion DTO -> Entité (inclut la validation de la catégorie)
        Produit produit = convertToEntity(productDTO);

        // Sauvegarde via le service
        Produit savedProduit = produitService.createProduit(produit);

        return ResponseEntity.ok(savedProduit);
    }

    private Produit convertToEntity(ProductDTO dto) {
        Produit produit = new Produit();
        produit.setNom(dto.getNom());
        produit.setDescription(dto.getDescription());
        produit.setMarque(dto.getMarque());
        produit.setPrixUnitaire(dto.getPrixUnitaire() != null ? dto.getPrixUnitaire().floatValue() : null);
        produit.setImageUrl(dto.getImageUrl());
        produit.setImageBase64(dto.getImageBase64());

        if (dto.getCategorieId() == null) {
            throw new IllegalArgumentException("categorieId is required");
        }

        CatégorieProduit categorie = categorieProduitRepository.findById(dto.getCategorieId())
                .orElseThrow(() -> new RuntimeException("Catégorie introuvable avec ID: " + dto.getCategorieId()));
        produit.setCategorie(categorie);

        return produit;
    }

    @GetMapping
    public List<ProduitResponseDTO> getAllProduits() {
        List<Produit> produits = produitService.getAllProduits();

        return produits.stream().map(produit -> {
            ProduitResponseDTO dto = new ProduitResponseDTO();
            dto.setId(produit.getId());
            dto.setNom(produit.getNom());
            dto.setDescription(produit.getDescription());
            dto.setMarque(produit.getMarque());
            dto.setPrixUnitaire(produit.getPrixUnitaire());
            dto.setImageUrl(produit.getImageUrl());
            dto.setImageBase64(produit.getImageBase64());

            List<PromotionDTO> promoDtos = new ArrayList<>();

            // 1. Promotions liées à la catégorie (filtrées par date)
            if (produit.getCategorie() != null) {
                List<PromotionDTO> promosCategorie = produit.getCategorie().getPromotions().stream()
                        .filter(p -> {
                            LocalDate today = LocalDate.now();
                            return (p.getDateDebut() == null || !p.getDateDebut().isAfter(today)) &&
                                    (p.getDateFin() == null || !p.getDateFin().isBefore(today));
                        })
                        .map(p -> {
                            PromotionDTO pDto = new PromotionDTO();
                            pDto.setId(p.getId());
                            pDto.setNom(p.getNom());
                            pDto.setTauxReduction(p.getTauxReduction());
                            pDto.setType(p.getType());
                            if (p.getProduitOffert() != null) {
                                pDto.setProduitOffertNom(p.getProduitOffert().getNom());
                            }
                            if (p.getProduitCondition() != null) {
                                pDto.setProduitConditionNom(p.getProduitCondition().getNom());
                                pDto.setQuantiteCondition(p.getQuantiteCondition());
                            }
                            pDto.setQuantiteOfferte(p.getQuantiteOfferte());
                            pDto.setDateDebut(p.getDateDebut());
                            pDto.setDateFin(p.getDateFin());
                            return pDto;
                        })
                        .toList();

                promoDtos.addAll(promosCategorie);
            }

            // 2. Promotions "CADEAU" liées au produit par nom
            List<Promotion> promoCadeaux = produitService.getPromotionsCadeauxParProduit(produit.getNom());
            List<PromotionDTO> promoCadeauxDTO = promoCadeaux.stream().map(p -> {
                PromotionDTO pDto = new PromotionDTO();
                pDto.setId(p.getId());
                pDto.setNom(p.getNom());
                pDto.setType(p.getType());
                pDto.setTauxReduction(p.getTauxReduction());

                if (p.getProduitCondition() != null) {
                    pDto.setProduitConditionNom(p.getProduitCondition().getNom());
                    pDto.setQuantiteCondition(p.getQuantiteCondition());
                }

                if (p.getProduitOffert() != null) {
                    pDto.setProduitOffertNom(p.getProduitOffert().getNom());
                }

                pDto.setQuantiteOfferte(p.getQuantiteOfferte());
                pDto.setDateDebut(p.getDateDebut());
                pDto.setDateFin(p.getDateFin());

                return pDto;
            }).toList();

            promoDtos.addAll(promoCadeauxDTO);

            // Set des promotions fusionnées
            dto.setPromotions(promoDtos);

            // Catégorie
            if (produit.getCategorie() != null) {
                dto.setCategorieId(produit.getCategorie().getId());
                dto.setCategorieNom(produit.getCategorie().getNom());
            }

            return dto;
        }).toList();
    }



    @GetMapping("/{id}")
    public Produit getProduitById(@PathVariable Long id) {
        return produitService.getProduitById(id);
    }

    @PutMapping("/{id}")
    @Transactional
    public ResponseEntity<?> updateProduit(
            @PathVariable Long id,
            @RequestBody ProduitUpdateDTO produitDTO) {

        try {
            // 🔒 Vérifie que l'utilisateur est admin
            getCurrentAdmin();

            Produit produit = produitRepository.findById(id)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Produit non trouvé"));

            // Mise à jour des champs
            produit.setNom(produitDTO.getNom());
            produit.setDescription(produitDTO.getDescription());
            produit.setMarque(produitDTO.getMarque());
            produit.setPrixUnitaire(produitDTO.getPrixUnitaire());
            produit.setImageUrl(produitDTO.getImageUrl());
            produit.setImageBase64(produitDTO.getImageBase64());

            // Catégorie
            if (produitDTO.getCategorieId() != null) {
                CatégorieProduit categorie = categorieProduitRepository.findById(produitDTO.getCategorieId())
                        .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Catégorie invalide"));
                produit.setCategorie(categorie);
            }

            // ApprouvePar
            if (produitDTO.getApprouveParId() != null) {
                Utilisateur approver = utilisateurRepository.findById(produitDTO.getApprouveParId())
                        .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Approver invalide"));
                produit.setApprouvePar(approver);
            }

            Produit updatedProduit = produitRepository.save(produit);
            return ResponseEntity.ok(updatedProduit);

        } catch (ResponseStatusException ex) {
            return ResponseEntity.status(ex.getStatusCode()).body(ex.getReason());
        } catch (RuntimeException ex) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(ex.getMessage());
        } catch (Exception ex) {
            return ResponseEntity.internalServerError().body("Erreur lors de la mise à jour");
        }
    }



    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteProduit(@PathVariable Long id) {
        try {
            getCurrentAdmin();
            produitService.deleteProduit(id);
            return ResponseEntity.ok("Produit supprimé avec succès.");
        } catch (RuntimeException ex) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(ex.getMessage());
        } catch (Exception ex) {
            return ResponseEntity.internalServerError().body("Erreur lors de la suppression");
        }
    }


}
