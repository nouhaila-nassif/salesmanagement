package com.example.backend.controller;
import com.example.backend.dto.*;
import com.example.backend.entity.Administrateur;
import com.example.backend.entity.ResponsableUnite;
import com.example.backend.entity.Superviseur;
import com.example.backend.entity.Utilisateur;
import com.example.backend.service.ClientService;
import com.example.backend.service.UtilisateurService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import com.example.backend.entity.Promotion; // <--- ADD THIS LINE

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@CrossOrigin(origins = "http://localhost:4200")
@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired
    private UtilisateurService utilisateurService;
    @Autowired
    private ClientService clientService;

    private Utilisateur getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        return utilisateurService.findByNomUtilisateur(username);
    }
    /**
     * Administrateur : voir tous les clients
     */
    @GetMapping("/clients")
    public ResponseEntity<?> getAllClients() {
        Utilisateur user = getCurrentUser();


        List<ClientDTO> clientDTOs = clientService.getAllClientsWithDetails().stream()
                .map(client -> new ClientDTO(
                        client.getId(),
                        client.getNom(),
                        client.getType(),
                        client.getTelephone(),
                        client.getEmail(),
                        client.getAdresse(),
                        client.getDerniereVisite(),
                        client.getRoutes() != null
                                ? client.getRoutes().stream()
                                .map(route -> new RouteNomDTO(route.getId(), route.getNom())) // ✅ avec id
                                .collect(Collectors.toSet())
                                : null
                ))
                .collect(Collectors.toList());

        return ResponseEntity.ok(clientDTOs);


    }
    /**
     * Administrateur : voir tous les utilisateurs
     */
    /**
     * Administrateur : voir tous les vendeurs (vendeurs + pré-vendeurs + vendeurs directs)
     */
    @GetMapping("/vendeurs")
    public ResponseEntity<List<UtilisateurDTO>> getAllVendeurs() {
        Utilisateur user = getCurrentUser();

        if (!(user instanceof Administrateur)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(null);
        }

        List<Utilisateur> vendeurs = utilisateurService.findAllVendeurs();

        List<UtilisateurDTO> dtos = vendeurs.stream().map(utilisateur -> {
            // Mapping des routes
            List<RouteDTO> routeDTOs = utilisateur.getRoutes() != null ? utilisateur.getRoutes().stream()
                    .map(route -> new RouteDTO(route.getId(), route.getNom()))
                    .toList() : List.of();

            // Mapping des commandes
            List<CommandeDTO> commandeDTOs = utilisateur.getCommandes() != null ? utilisateur.getCommandes().stream()
                    .map(commande -> {
                        List<LigneCommandeDTO> ligneDTOs = commande.getLignes() != null ? commande.getLignes().stream()
                                .map(ligne -> new LigneCommandeDTO(
                                        ligne.getId(),                             // Long id
                                        ligne.getQuantite(),                       // int quantite
                                        ligne.getProduit().getId(),                // Long produitId
                                        new ProductDTO(ligne.getProduit()),        // ProductDTO produit
                                        BigDecimal.valueOf(ligne.getProduit().getPrixUnitaire()),  // prixUnitaireOriginal
                                        ligne.getPrixUnitaireReduit(),             // prixUnitaireReduit (BigDecimal)
                                        ligne.getReductionLigne()                   // reductionLigne (BigDecimal)
                                ))



                                .toList() : List.of();


                        return new CommandeDTO(
                                commande.getId(),
                                commande.getDateCreation(),
                                commande.getStatut(),
                                (commande.getClient() != null) ? commande.getClient().getId() : null,
                                (commande.getVendeur() != null) ? commande.getVendeur().getId() : null,
                                (commande.getApprouvePar() != null) ? commande.getApprouvePar().getId() : null,
                                (commande.getVendeur() != null) ? commande.getVendeur().getNomUtilisateur() : null,
                                (commande.getClient() != null) ? commande.getClient().getNom() : null,
                                (commande.getApprouvePar() != null) ? commande.getApprouvePar().getNomUtilisateur() : null,
                                ligneDTOs,
                                commande.getDateLivraison(),
                                commande.getMontantReduction() != null ? commande.getMontantReduction() : BigDecimal.ZERO,
                                // New fields added to the constructor:
                                commande.getMontantTotal() != null ? commande.getMontantTotal() : BigDecimal.ZERO, // montantTotal
                                commande.getMontantTotalAvantRemise() != null ? commande.getMontantTotalAvantRemise() : BigDecimal.ZERO, // montantTotalAvantRemise
                                // Promotions IDs. This is where the conversion from Set<Promotion> to List<Long> happens
                                (commande.getPromotions() != null) ?
                                        commande.getPromotions().stream()
                                                .map(Promotion::getId)
                                                .collect(Collectors.toList())
                                        : Collections.emptyList() // If no promotions, provide an empty list
                        );


                    })
                    .toList() : List.of();

            return new UtilisateurDTO(
                    utilisateur.getId(),
                    utilisateur.getNomUtilisateur(),
                    utilisateur.getTelephone(),   // ajout
                    utilisateur.getEmail(),       // ajout
                    routeDTOs,
                    commandeDTOs
            );

        }).toList();

        return ResponseEntity.ok(dtos);
    }


    @GetMapping()
    public ResponseEntity<List<UtilisateurDTO>> getAllUtilisateurs() {
        List<Utilisateur> utilisateurs = utilisateurService.getAllUtilisateurs();

        List<UtilisateurDTO> dtos = utilisateurs.stream().map(utilisateur -> {
            // Mapping des routes
            List<RouteDTO> routeDTOs = utilisateur.getRoutes() != null ? utilisateur.getRoutes().stream()
                    .map(route -> new RouteDTO(route.getId(), route.getNom()))
                    .toList() : List.of();

            // Mapping des commandes
            List<CommandeDTO> commandeDTOs = utilisateur.getCommandes() != null ? utilisateur.getCommandes().stream()
                    .map(commande -> {
                        List<LigneCommandeDTO> ligneDTOs = commande.getLignes() != null ? commande.getLignes().stream()
                                .map(ligne -> new LigneCommandeDTO(
                                        ligne.getId(),                                    // Long id
                                        ligne.getQuantite(),                              // int quantite
                                        ligne.getProduit().getId(),                       // Long produitId
                                        new ProductDTO(ligne.getProduit()),               // ProductDTO produit
                                        BigDecimal.valueOf(ligne.getProduit().getPrixUnitaire()),  // prixUnitaireOriginal (avant promo)
                                        ligne.getPrixUnitaireReduit() != null ? ligne.getPrixUnitaireReduit() : BigDecimal.ZERO,  // prixUnitaireReduit (après promo)
                                        ligne.getReductionLigne() != null ? ligne.getReductionLigne() : BigDecimal.ZERO          // reductionLigne
                                ))




                                .toList() : List.of();


                        return new CommandeDTO(
                                commande.getId(),
                                commande.getDateCreation(),
                                commande.getStatut(),
                                (commande.getClient() != null) ? commande.getClient().getId() : null,
                                (commande.getVendeur() != null) ? commande.getVendeur().getId() : null,
                                (commande.getApprouvePar() != null) ? commande.getApprouvePar().getId() : null,
                                (commande.getVendeur() != null) ? commande.getVendeur().getNomUtilisateur() : null,
                                (commande.getClient() != null) ? commande.getClient().getNom() : null,
                                (commande.getApprouvePar() != null) ? commande.getApprouvePar().getNomUtilisateur() : null,
                                ligneDTOs,
                                commande.getDateLivraison(),
                                commande.getMontantReduction() != null ? commande.getMontantReduction() : BigDecimal.ZERO,
                                // New fields added to the constructor:
                                commande.getMontantTotal() != null ? commande.getMontantTotal() : BigDecimal.ZERO, // montantTotal
                                commande.getMontantTotalAvantRemise() != null ? commande.getMontantTotalAvantRemise() : BigDecimal.ZERO, // montantTotalAvantRemise
                                // Promotions IDs. This is where the conversion from Set<Promotion> to List<Long> happens
                                (commande.getPromotions() != null) ?
                                        commande.getPromotions().stream()
                                                .map(Promotion::getId)
                                                .collect(Collectors.toList())
                                        : Collections.emptyList() // If no promotions, provide an empty list
                        );

                    })
                    .toList() : List.of();

            return new UtilisateurDTO(
                    utilisateur.getId(),
                    utilisateur.getNomUtilisateur(),
                    utilisateur.getTelephone(),   // ajout
                    utilisateur.getEmail(),       // ajout
                    routeDTOs,
                    commandeDTOs
            );

        }).toList();

        return ResponseEntity.ok(dtos);
    }

    @GetMapping("/superviseur/assignes")
    public ResponseEntity<?> getAssignesSuperviseur() {
        Utilisateur user = getCurrentUser();
        if (!(user instanceof Superviseur superviseur)) {
            return ResponseEntity.status(403).body("Accès refusé : utilisateur non superviseur.");
        }

        var result = Map.of(
                "preVendeurs", superviseur.getPreVendeurs(),
                "vendeursDirects", superviseur.getVendeursDirects()
        );

        return ResponseEntity.ok(result);
    }


    /**
     * Responsable d’unité : voir superviseurs sous sa responsabilité
     */
    @GetMapping("/responsable-unite/superviseurs")
    public ResponseEntity<?> getSuperviseursResponsable(@RequestAttribute("user") Utilisateur user) {
        if (!(user instanceof ResponsableUnite responsable)) {
            return ResponseEntity.status(403).body("Accès refusé : utilisateur non responsable d’unité.");
        }

        var superviseurs = responsable.getSuperviseurs();

        return ResponseEntity.ok(superviseurs);
    }

    /**
     * Administrateur : voir tous les superviseurs (exemple)
     */
    @GetMapping("/admin/superviseurs")
    public ResponseEntity<?> getAllSuperviseurs() {
        Utilisateur user = getCurrentUser();
        if (!(user instanceof Administrateur)) {
            return ResponseEntity.status(403).body("Accès refusé : utilisateur non administrateur.");
        }

        var superviseurs = utilisateurService.findAllSuperviseurs();

        return ResponseEntity.ok(superviseurs);
    }

}
