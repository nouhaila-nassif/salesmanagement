package com.example.backend.controller;

import com.example.backend.dto.RouteDTO;
import com.example.backend.entity.Administrateur;
import com.example.backend.entity.Route;
import com.example.backend.entity.Superviseur;
import com.example.backend.entity.Utilisateur;
import com.example.backend.service.RouteService;
import com.example.backend.service.UtilisateurService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/routes")
public class RouteController {

    @Autowired
    private RouteService routeService;

    @Autowired
    private UtilisateurService utilisateurService;

    // Vérifie que l'utilisateur courant est un administrateur
    private Utilisateur getCurrentAdmin() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        Utilisateur admin = utilisateurService.findByNomUtilisateur(username);

        if (!(admin instanceof Administrateur || admin instanceof Superviseur)) {
            throw new RuntimeException("Accès refusé : vous devez être un administrateur ou un superviseur.");
        }


        return admin;
    }

    // CREATE - réservé aux admins
    @PostMapping("/create")
    public Route createRoute(@RequestBody RouteDTO routeDTO) {
        getCurrentAdmin(); // Vérifie les droits
        return routeService.createRoute(routeDTO);
    }
    @DeleteMapping("/routes/{routeId}/vendeurs")
    public ResponseEntity<Void> supprimerTousLesVendeurs(@PathVariable Long routeId) {
        routeService.dissocierTousLesVendeurs(routeId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/routes/{routeId}/clients")
    public ResponseEntity<Void> supprimerTousLesClients(@PathVariable Long routeId) {
        routeService.dissocierTousLesClients(routeId);
        return ResponseEntity.noContent().build();
    }

    // READ ALL
    @GetMapping
    public List<Route> getAllRoutes() {
        return routeService.getAllRoutes();
    }

    // READ BY ID
    @GetMapping("/{id}")
    public Route getRouteById(@PathVariable Long id) {
        return routeService.getRouteById(id);
    }

    // UPDATE - réservé aux admins
    @PutMapping("/{id}")
    public Route updateRoute(@PathVariable Long id, @RequestBody RouteDTO updatedRouteDTO) {
        getCurrentAdmin();
        return routeService.updateRoute(id, updatedRouteDTO);
    }

    // DELETE - réservé aux admins
    @DeleteMapping("/{id}")
    public void deleteRoute(@PathVariable Long id) {
        getCurrentAdmin();
        routeService.deleteRoute(id);
    }
}
