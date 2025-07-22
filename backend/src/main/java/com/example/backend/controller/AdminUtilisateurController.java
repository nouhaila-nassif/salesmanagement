package com.example.backend.controller;

import com.example.backend.dto.*;
import com.example.backend.entity.*;
import com.example.backend.repository.AdministrateurRepository;
import com.example.backend.repository.UtilisateurRepository;
import com.example.backend.service.AdminUtilisateurService;
import com.example.backend.service.UtilisateurService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.TransactionException;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/utilisateurs")

public class AdminUtilisateurController {
    private final AdminUtilisateurService service;

    @Autowired
    private UtilisateurRepository utilisateurRepository;
    public AdminUtilisateurController(AdminUtilisateurService service) {
        this.service = service;


    }

    @GetMapping("/superviseurs/vendeurs")
    public List<UtilisateurResponse> getVendeursByConnectedSuperviseur() {
        // 1. Obtenir le superviseur connecté
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();

        Utilisateur superviseur = utilisateurRepository.findByNomUtilisateur(username)
                .orElseThrow(() -> new RuntimeException("Superviseur non trouvé"));

        // 2. Récupérer tous les vendeurs
        List<Utilisateur> utilisateurs = utilisateurRepository.findAll();

        // 3. Filtrer uniquement les vendeurs assignés à ce superviseur
        return utilisateurs.stream()
                .filter(u -> (u instanceof VendeurDirect || u instanceof PreVendeur))
                .filter(u -> {
                    if (u instanceof VendeurDirect vd) {
                        return vd.getSuperviseur() != null && vd.getSuperviseur().getId().equals(superviseur.getId());
                    } else if (u instanceof PreVendeur pv) {
                        return pv.getSuperviseur() != null && pv.getSuperviseur().getId().equals(superviseur.getId());
                    }
                    return false;
                })
                .map(u -> {
                    if (u instanceof VendeurDirect vd) {
                        return new UtilisateurResponse(vd);
                    } else {
                        return new UtilisateurResponse((PreVendeur) u);
                    }
                })
                .toList();
    }

    @PutMapping("/vendeursdirect/{id}")
    public ResponseEntity<?> modifierVendeur(
            @PathVariable Long id,
            @RequestBody VendeurDirectUpdateDTO dto) {

        try {
            Utilisateur updatedVendeur = service.modifierVendeurDirect(
                    id,
                    dto.getNomUtilisateur(),
                    dto.getMotDePasse(),
                    dto.getSuperviseurId()
            );
            return ResponseEntity.ok(updatedVendeur);

        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(e.getMessage());
        }
    }


    @PostMapping("/create")
    public ResponseEntity<?> createUser(@RequestBody CreateUtilisateurRequest request) {
        try {
            if (request.getRole() == null || request.getRole().trim().isEmpty()) {
                return ResponseEntity.badRequest().body("Le champ 'role' est requis.");
            }

            String role = request.getRole().toUpperCase();

            switch (role) {
                case "ADMIN": {
                    Utilisateur createdUser = service.creerAdministrateur(
                            request.getUsername(),
                            request.getPassword(),
                            request.getTelephone(),
                            request.getEmail()
                    );
                    UtilisateurResponse response = new UtilisateurResponse(createdUser);
                    return ResponseEntity.status(HttpStatus.CREATED).body(response);
                }
                case "SUPERVISEUR": {
                    Superviseur createdUser = service.creerSuperviseur(
                            request.getUsername(),
                            request.getPassword(),
                            request.getTelephone(),
                            request.getEmail()
                    );
                    UtilisateurResponse response = new UtilisateurResponse(createdUser);
                    return ResponseEntity.status(HttpStatus.CREATED).body(response);
                }
                case "PREVENDEUR": {
                    if (request.getSuperviseurId() == null) {
                        return ResponseEntity.badRequest().body("Le champ 'superviseurId' est requis pour un PREVENDEUR.");
                    }
                    if (request.getTelephone() == null || request.getTelephone().trim().isEmpty() ||
                            request.getEmail() == null || request.getEmail().trim().isEmpty()) {
                        return ResponseEntity.badRequest().body("Les champs 'telephone' et 'email' sont requis pour un PREVENDEUR.");
                    }
                    try {
                        PreVendeurDTO preVendeurDTO = service.creerPreVendeur(
                                request.getUsername(),
                                request.getPassword(),
                                request.getSuperviseurId(),
                                request.getTelephone(),
                                request.getEmail()
                        );
                        return ResponseEntity.status(HttpStatus.CREATED).body(preVendeurDTO);
                    } catch (IllegalArgumentException e) {
                        return ResponseEntity.badRequest().body(e.getMessage());
                    }
                }
                case "VENDEURDIRECT": {
                    if (request.getSuperviseurId() == null) {
                        return ResponseEntity.badRequest().body("Le champ 'superviseurId' est requis pour un VENDEURDIRECT.");
                    }
                    if (request.getTelephone() == null || request.getTelephone().trim().isEmpty() ||
                            request.getEmail() == null || request.getEmail().trim().isEmpty()) {
                        return ResponseEntity.badRequest().body("Les champs 'telephone' et 'email' sont requis pour un VENDEURDIRECT.");
                    }
                    try {
                        VendeurDirectDTO vendeurDTO = service.creerVendeurDirect(
                                request.getUsername(),
                                request.getPassword(),
                                request.getSuperviseurId(),
                                request.getTelephone(),
                                request.getEmail()
                        );
                        return ResponseEntity.status(HttpStatus.CREATED).body(vendeurDTO);
                    } catch (IllegalArgumentException e) {
                        return ResponseEntity.badRequest().body(e.getMessage());
                    }
                }
                default:
                    return ResponseEntity.badRequest().body("Rôle non reconnu : " + request.getRole());
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Erreur lors de la création de l'utilisateur : " + e.getMessage());
        }
    }

    @GetMapping
    public ResponseEntity<List<UtilisateurResponse>> getAllUsers() {
        List<Utilisateur> users = service.getAllUsersWithSuperviseur();
        List<UtilisateurResponse> responses = users.stream()
                .map(UtilisateurResponse::new)
                .collect(Collectors.toList());
        return ResponseEntity.ok(responses);
    }





    @GetMapping("/vendeurs")
    public ResponseEntity<List<UtilisateurResponse>> getAllVendeurs() {
        List<UtilisateurResponse> vendeurs = service.getAllVendeurs();
        return ResponseEntity.ok(vendeurs);
    }


    @GetMapping("/prevendeurs")
    public ResponseEntity<List<UtilisateurResponse>> getAllPreVendeurs() {
        List<UtilisateurResponse> prevendeurs = service.getAllPreVendeurs();
        return ResponseEntity.ok(prevendeurs);
    }





    // Suppression avec réassignation si superviseur
    @DeleteMapping("/{id}")
    public ResponseEntity<?> supprimerUtilisateurAvecReassignation(@PathVariable("id") Long id) {
        try {
            service.supprimerUtilisateurAvecReassignation(id);
            return ResponseEntity.noContent().build(); // <-- Pour que le status code soit 204
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erreur lors de la suppression.");
        }
    }   // Modifier un utilisateur existant

    @PutMapping("/{id}")
    public ResponseEntity<Utilisateur> modifierUtilisateur(
            @PathVariable Long id,
            @RequestBody UpdateUtilisateurRequest request) {

        Utilisateur utilisateurModifie = service.modifierUtilisateur(id, request);
        if (utilisateurModifie == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(utilisateurModifie);
    }





    // Récupérer un utilisateur par son id
    @GetMapping("/{id}")
    public ResponseEntity<Utilisateur> getUtilisateur(@PathVariable Long id) {
        try {
            Utilisateur utilisateur = service.getUtilisateur(id);
            return ResponseEntity.ok(utilisateur);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        }
    }

}
