package com.example.backend.controller;

import com.example.backend.service.RouteManagementService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/routes")
public class RouteManagementController {

    private static final Logger logger = LoggerFactory.getLogger(RouteManagementController.class);

    private final RouteManagementService routeManagementService;

    public RouteManagementController(RouteManagementService routeManagementService) {
        this.routeManagementService = routeManagementService;
    }

    @PostMapping("/{routeId}/assignUser/{userId}")
    public ResponseEntity<Map<String, String>> assignRouteToUtilisateur(@PathVariable Long routeId, @PathVariable Long userId) {
        try {
            routeManagementService.assignerUtilisateurARoute(userId, routeId);
            return ResponseEntity.ok(Map.of("message", "Route assignée à l'utilisateur avec succès."));
        } catch (Exception e) {
            logger.error("Erreur lors de l'assignation de l'utilisateur à la route", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Erreur lors de l'assignation de l'utilisateur : " + e.getMessage()));
        }
    }

    @PostMapping("/{routeId}/assignClient/{clientId}")
    public ResponseEntity<Map<String, String>> assignClientToRoute(@PathVariable Long routeId, @PathVariable Long clientId) {
        try {
            routeManagementService.assignerClientARoute(clientId, routeId);
            return ResponseEntity.ok(Map.of("message", "Client assigné à la route avec succès."));
        } catch (Exception e) {
            logger.error("Erreur lors de l'assignation du client à la route", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Erreur lors de l'assignation du client : " + e.getMessage()));
        }
    }

    @DeleteMapping("/{routeId}/clients/{clientId}")
    public ResponseEntity<Map<String, String>> unassignClient(@PathVariable Long routeId, @PathVariable Long clientId) {
        try {
            routeManagementService.unassignClient(routeId, clientId);
            return ResponseEntity.ok(Map.of("message", "Client dissocié de la route avec succès."));
        } catch (Exception e) {
            logger.error("Erreur lors de la dissociation du client de la route", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Erreur lors de la dissociation du client : " + e.getMessage()));
        }
    }

    @PostMapping("/{routeId}/assignVendeur/{vendeurId}")
    public ResponseEntity<Map<String, String>> assignVendeurToRoute(@PathVariable Long routeId, @PathVariable Long vendeurId) {
        try {
            routeManagementService.assignerVendeurARoute(vendeurId, routeId);
            return ResponseEntity.ok(Map.of("message", "Vendeur assigné à la route avec succès."));
        } catch (Exception e) {
            logger.error("Erreur lors de l'assignation du vendeur à la route", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Erreur lors de l'assignation du vendeur : " + e.getMessage()));
        }
    }
}
