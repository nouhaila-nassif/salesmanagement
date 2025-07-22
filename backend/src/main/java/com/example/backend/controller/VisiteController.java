package com.example.backend.controller;

import com.example.backend.dto.VisiteRequest;
import com.example.backend.dto.VisiteSimpleDTO;
import com.example.backend.entity.*;
import com.example.backend.service.ClientService;
import com.example.backend.service.PreVendeurService;
import com.example.backend.service.UtilisateurService;
import com.example.backend.service.VisiteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/visites")
public class VisiteController {

    private final VisiteService visiteService;
    private final ClientService clientService;
    private final PreVendeurService preVendeurService;
    @Autowired
    private UtilisateurService utilisateurService;
    private Utilisateur getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();

        Utilisateur utilisateur = utilisateurService.findByNomUtilisateur(username);
        if (utilisateur == null) {
            throw new RuntimeException("Utilisateur non trouvé : " + username);
        }
        return utilisateur;
    }

    @Autowired
    public VisiteController(VisiteService visiteService,
                            ClientService clientService,
                            PreVendeurService preVendeurService) {
        this.visiteService = visiteService;
        this.clientService = clientService;
        this.preVendeurService = preVendeurService;
    }

    // Endpoint pour planifier automatiquement les visites
    @PostMapping("/planification-auto")
    public ResponseEntity<List<VisiteSimpleDTO>> planifierVisitesAutomatiques() {
        List<VisiteSimpleDTO> result = visiteService.planifierVisitesAutomatiques();
        return ResponseEntity.ok(result);
    }




    @GetMapping("/toutes")
    public ResponseEntity<List<VisiteSimpleDTO>> getToutesLesVisites() {
        List<VisiteSimpleDTO> visitesDto = visiteService.getToutesLesVisites();
        return ResponseEntity.ok(visitesDto);
    }

    @GetMapping("/mes-visites")
    public List<VisiteSimpleDTO> getVisitesForCurrentUser() {
        Utilisateur utilisateur = getCurrentUser(); // méthode partagée pour récupérer l'utilisateur connecté

        List<Visite> visites;

        // Si admin → retourne toutes les visites
        if (utilisateur instanceof Administrateur || "ADMIN".equals(utilisateur.getRole())) {
            visites = visiteService.getToutesLesVisitesEntities(); // retourne les entités (non DTO)
        }
        // Si vendeur ou pré-vendeur → retourne uniquement les visites liées à ses clients
        else if ("VENDEURDIRECT".equals(utilisateur.getRole()) || "PREVENDEUR".equals(utilisateur.getRole())) {
            visites = visiteService.getVisitesParVendeur(utilisateur.getId());
        } else {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Accès réservé aux vendeurs et administrateurs");
        }

        // Mapping vers DTO
        return visites.stream()
                .map(visiteService::toVisiteSimpleDTO)
                .collect(Collectors.toList());
    }

    // Endpoint pour créer une visite manuelle
//    @PostMapping("/create")
//    public ResponseEntity<?> createVisite(@RequestBody VisiteRequest request) {
//        try {
//            Client client = clientService.getClientById(request.getClientId());
//            PreVendeur vendeur = preVendeurService.getPreVendeurById(request.getVendeurId());
//
//            Visite visite = visiteService.createVisite(client, vendeur, request.getDatePlanifiee());
//            VisiteSimpleDTO dto = visiteService.toVisiteSimpleDTO(visite);
//
//            return ResponseEntity.ok(dto);
//
//        } catch (IllegalArgumentException | IllegalStateException e) {
//            return ResponseEntity.badRequest().body(e.getMessage());
//        } catch (Exception e) {
//            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erreur serveur");
//        }
//    }
//



    // Endpoint pour reporter une visite
    @PutMapping("/reporter/{id}")
    public ResponseEntity<Visite> reporterVisite(
            @PathVariable Long id,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate newDate,
            @RequestParam(required = false) String raison) {

        Visite visiteReportee = visiteService.reporterVisite(id, newDate, raison);
        return ResponseEntity.ok(visiteReportee);
    }

    // Endpoint pour obtenir les prochaines visites critiques (pour dashboard superviseur)
    @GetMapping("/prochaines-visites-critiques")
    public ResponseEntity<List<VisiteSimpleDTO>> getProchainesVisitesCritiques() {
        List<VisiteSimpleDTO> visites = visiteService.getProchainesVisitesCritiques();
        return ResponseEntity.ok(visites);
    }

}
