package com.example.backend.controller;

import com.example.backend.dto.ChargementRequest;
import com.example.backend.dto.ProduitStockDto;
import com.example.backend.dto.StockCamionDto;
import com.example.backend.entity.*;
import com.example.backend.repository.UtilisateurRepository;
import com.example.backend.service.StockCamionService;
import com.example.backend.service.UtilisateurService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/stock-camion")
public class StockCamionController {
    @Autowired
    private UtilisateurRepository utilisateurRepository;
    private final StockCamionService stockCamionService;
    @Autowired
    private
    UtilisateurService utilisateurService;
    public StockCamionController(StockCamionService stockCamionService) {
        this.stockCamionService = stockCamionService;
    }

    @DeleteMapping("/{stockId}/produit/{produitId}")
    public ResponseEntity<Void> supprimerProduitDuStock(@PathVariable Long stockId, @PathVariable Long produitId) {
        stockCamionService.supprimerProduitDuStock(stockId, produitId);
        return ResponseEntity.ok().build();
    }

    private Utilisateur getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();

        return utilisateurRepository.findByNomUtilisateur(username)
                .orElseThrow(() -> new UsernameNotFoundException("Utilisateur non trouvé : " + username));
    }
    // Voir son propre stock camion (Vendeur Direct)
    @GetMapping("/moi")
    public ResponseEntity<StockCamionDto> voirSonStock() {
        StockCamion stock = stockCamionService.voirSonStock();
        if (stock == null) {
            return ResponseEntity.notFound().build();
        }

        Utilisateur chauffeur = stock.getChauffeur();

        List<ProduitStockDto> produits = stock.getNiveauxStock().entrySet().stream()
                .map(entry -> {
                    Produit produit = entry.getKey();
                    int quantite = entry.getValue();

                    ProduitStockDto dto = new ProduitStockDto();
                    dto.setProduitId(produit.getId());
                    dto.setNom(produit.getNom());
                    dto.setDescription(produit.getDescription());
                    dto.setMarque(produit.getMarque());
                    dto.setPrixUnitaire(produit.getPrixUnitaire() != null
                            ? Double.valueOf(produit.getPrixUnitaire())
                            : 0.0);
                    dto.setImageBase64(produit.getImageBase64()); // String base64 déjà prête
                    dto.setQuantite(quantite);

                    return dto;
                })
                .collect(Collectors.toList());

        StockCamionDto dto = new StockCamionDto();
        dto.setId(stock.getId());
        dto.setChauffeur(chauffeur.getNomUtilisateur());
        dto.setNiveauxStock(produits);

        return ResponseEntity.ok(dto);
    }


     @GetMapping("/tous")
    public ResponseEntity<List<StockCamionDto>> voirTousLesStocks() {
        Utilisateur utilisateur = getCurrentUser(); // méthode utilitaire pour récupérer l'utilisateur connecté
        List<StockCamion> stocks;

        switch (utilisateur.getRole()) {
            case "ADMIN":
                // Tous les stocks visibles
                stocks = stockCamionService.voirTousLesStocks();
                break;

            case "SUPERVISEUR":
                // Filtrer les stocks par vendeurs supervisés
                List<Utilisateur> vendeurs = utilisateurRepository.findAll().stream()
                        .filter(u -> (u instanceof VendeurDirect || u instanceof PreVendeur))
                        .filter(u -> {
                            if (u instanceof VendeurDirect vd) {
                                return vd.getSuperviseur() != null && vd.getSuperviseur().getId().equals(utilisateur.getId());
                            } else if (u instanceof PreVendeur pv) {
                                return pv.getSuperviseur() != null && pv.getSuperviseur().getId().equals(utilisateur.getId());
                            }
                            return false;
                        })
                        .toList();

                List<Long> idsDesVendeurs = vendeurs.stream()
                        .map(Utilisateur::getId)
                        .toList();

                // Charger uniquement les stocks des vendeurs supervisés
                stocks = stockCamionService.voirTousLesStocks().stream()
                        .filter(stock -> stock.getChauffeur() != null &&
                                idsDesVendeurs.contains(stock.getChauffeur().getId()))
                        .toList();
                break;

            default:
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Accès non autorisé");
        }

        // Mapper les entités vers DTO
        List<StockCamionDto> dtoList = stocks.stream()
                .map(stock -> {
                    StockCamionDto dto = new StockCamionDto();
                    dto.setId(stock.getId());

                    String nomChauffeur = stock.getChauffeur() != null
                            ? stock.getChauffeur().getNomUtilisateur()
                            : "Inconnu";
                    dto.setChauffeur(nomChauffeur);

                    List<ProduitStockDto> produits = stock.getNiveauxStock().entrySet().stream()
                            .map(entry -> {
                                Produit produit = entry.getKey();
                                int quantite = entry.getValue();

                                ProduitStockDto pDto = new ProduitStockDto();
                                pDto.setProduitId(produit.getId());
                                pDto.setNom(produit.getNom());
                                pDto.setDescription(produit.getDescription());
                                pDto.setMarque(produit.getMarque());
                                pDto.setPrixUnitaire(produit.getPrixUnitaire() != null
                                        ? Double.valueOf(produit.getPrixUnitaire())
                                        : 0.0);
                                pDto.setImageBase64(produit.getImageBase64());
                                pDto.setQuantite(quantite);
                                return pDto;
                            })
                            .toList();

                    dto.setNiveauxStock(produits);
                    return dto;
                })
                .toList();

        return ResponseEntity.ok(dtoList);
    }




    @PostMapping("/charger")
    public ResponseEntity<String> chargerStock(@RequestBody ChargementRequest request) {
        stockCamionService.chargerStock(request.produitId, request.quantite, request.stockId);
        return ResponseEntity.ok("Stock chargé avec succès");
    }
    @PostMapping("/creer")
    public ResponseEntity<StockCamion> creerStock() {
        Utilisateur user = utilisateurService.getUtilisateurActuel();
        if (!(user instanceof VendeurDirect)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        StockCamion stock = stockCamionService.creerStockPourVendeur((VendeurDirect) user);
        return ResponseEntity.ok(stock);
    }

    // Déduire du stock après vente (Vendeur Direct auto)
    @PostMapping("/deduire")
    public ResponseEntity<String> deduireStock(@RequestParam Long produitId,
                                               @RequestParam int quantite) {
        stockCamionService.deduireStock(produitId, quantite);
        return ResponseEntity.ok("Stock déduit avec succès");
    }

    // Visualiser stock  vendeurs (Admin, Superviseur, Responsable Unité)

    @DeleteMapping("/supprimer/{stockId}")
    public ResponseEntity<String> supprimerStock(@PathVariable Long stockId) {
        stockCamionService.supprimerStock(stockId);
        return ResponseEntity.ok("Stock supprimé avec succès.");
    }


    // Modifier stock manuellement (Admin seulement)
    @PutMapping("/modifier")
    public ResponseEntity<String> modifierManuellement(@RequestParam Long stockId,
                                                       @RequestParam Long produitId,
                                                       @RequestParam int nouvelleQuantite) {
        stockCamionService.modifierManuellement(stockId, produitId, nouvelleQuantite);
        return ResponseEntity.ok("Stock modifié avec succès");
    }
}
