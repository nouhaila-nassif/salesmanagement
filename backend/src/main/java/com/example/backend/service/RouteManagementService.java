package com.example.backend.service;

import com.example.backend.entity.*;
import com.example.backend.repository.ClientRepository;
import com.example.backend.repository.RouteRepository;
import com.example.backend.repository.UtilisateurRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;

@Service
public class RouteManagementService {

    @Autowired
    private RouteRepository routeRepository;

    @Autowired
    private ClientRepository clientRepository;

    @Autowired
    private UtilisateurRepository utilisateurRepository;

    public void assignerUtilisateurARoute(Long utilisateurId, Long routeId) {
        Utilisateur utilisateur = utilisateurRepository.findById(utilisateurId)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RuntimeException("Route non trouvée"));

        // Ajout de la route à l'utilisateur
        utilisateur.getRoutes().add(route);
        // Ajout de l'utilisateur à la liste des vendeurs de la route
        route.getVendeurs().add(utilisateur);

        utilisateurRepository.save(utilisateur);
        routeRepository.save(route);
    }
    @Transactional
    public void unassignClient(Long routeId, Long clientId) {
        Client client = clientRepository.findById(clientId)
                .orElseThrow(() -> new RuntimeException("Client non trouvé"));

        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RuntimeException("Route non trouvée"));

        client.getRoutes().remove(route);         // ⛔ retire la route du client
        route.getClients().remove(client);        // ⛔ retire le client de la route

        clientRepository.save(client);
        routeRepository.save(route);
    }

    @Transactional
    public void assignerClientARoute(Long clientId, Long routeId) {
        Client client = clientRepository.findById(clientId)
                .orElseThrow(() -> new RuntimeException("Client non trouvé"));
        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RuntimeException("Route non trouvée"));

        // Ajout dans les collections ManyToMany des deux côtés
        client.getRoutes().add(route);
        route.getClients().add(client);

        clientRepository.save(client);
        routeRepository.save(route);
    }

    @Transactional
    public void assignerVendeurARoute(Long vendeurId, Long routeId) {
        Utilisateur vendeur = utilisateurRepository.findById(vendeurId)
                .orElseThrow(() -> new RuntimeException("Vendeur non trouvé"));
        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RuntimeException("Route non trouvée"));

        if (route.getVendeurs() == null) {
            route.setVendeurs(new HashSet<>());
        }

        if (!route.getVendeurs().contains(vendeur)) {
            route.getVendeurs().add(vendeur);
        }

        if (vendeur.getRoutes() == null) {
            vendeur.setRoutes(new HashSet<>());
        }

        if (!vendeur.getRoutes().contains(route)) {
            vendeur.getRoutes().add(route);
        }

        utilisateurRepository.save(vendeur);
        routeRepository.save(route);
    }

}
