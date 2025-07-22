package com.example.backend.service;

import com.example.backend.dto.RouteDTO;
import com.example.backend.entity.Client;
import com.example.backend.entity.Route;
import com.example.backend.entity.Utilisateur;
import com.example.backend.entity.Vendeur;
import com.example.backend.repository.ClientRepository;
import com.example.backend.repository.RouteRepository;
import com.example.backend.repository.UtilisateurRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
public class RouteService {

    private final RouteRepository routeRepository;
    private final ClientRepository clientRepository;
    private final UtilisateurRepository utilisateurRepository;

    @Autowired
    public RouteService(RouteRepository routeRepository, ClientRepository clientRepository, UtilisateurRepository utilisateurRepository) {
        this.routeRepository = routeRepository;
        this.clientRepository = clientRepository;
        this.utilisateurRepository = utilisateurRepository;
    }

    public List<Route> getAllRoutes() {
        return routeRepository.findAll();
    }

    public Route getRouteById(Long id) {
        return routeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Route non trouvée avec l'ID : " + id));
    }

    @Transactional
    public Route createRoute(RouteDTO dto) {
        Route route = new Route();
        route.setNom(dto.getNom());

        // Associer les clients (ManyToMany)
        if (dto.getClientIds() != null && !dto.getClientIds().isEmpty()) {
            Set<Client> clients = new HashSet<>(clientRepository.findAllById(dto.getClientIds()));
            route.setClients(clients);

            // Optionnel : synchroniser le côté inverse si tu veux gérer les deux côtés
            for (Client client : clients) {
                client.getRoutes().add(route); // seulement si tu veux gérer les deux côtés
            }
        } else {
            route.setClients(new HashSet<>());
        }

        // Associer les vendeurs (ManyToMany)
        if (dto.getVendeurIds() != null && !dto.getVendeurIds().isEmpty()) {
            Set<Utilisateur> vendeurs = new HashSet<>(utilisateurRepository.findAllById(dto.getVendeurIds()));
            route.setVendeurs(vendeurs);

            for (Utilisateur vendeur : vendeurs) {
                vendeur.getRoutes().add(route);
            }
        } else {
            route.setVendeurs(new HashSet<>());
        }

        return routeRepository.save(route);
    }


    @Transactional
    public Route updateRoute(Long id, RouteDTO routeDTO) {
        Route route = routeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Route introuvable"));

        // ✅ Mettre à jour le nom si présent
        if (routeDTO.getNom() != null && !routeDTO.getNom().trim().isEmpty()) {
            route.setNom(routeDTO.getNom());
        }

        // ✅ Mettre à jour les vendeurs si la liste est fournie
        if (routeDTO.getVendeurIds() != null) {
            // Supprimer les anciennes associations
            for (Utilisateur ancienVendeur : new HashSet<>(route.getVendeurs())) {
                ancienVendeur.getRoutes().remove(route);
                utilisateurRepository.save(ancienVendeur);
            }
            route.getVendeurs().clear();

            // Ajouter les nouvelles associations
            Set<Utilisateur> nouveauxVendeurs = new HashSet<>(
                    utilisateurRepository.findAllById(routeDTO.getVendeurIds())
            );
            for (Utilisateur vendeur : nouveauxVendeurs) {
                vendeur.getRoutes().add(route);
                utilisateurRepository.save(vendeur);
            }

            route.setVendeurs(nouveauxVendeurs);
        }

        // ✅ Tu peux aussi ajouter le traitement des clients si routeDTO.getClientIds() != null ici

        return routeRepository.save(route);
    }



    @Transactional
    public void deleteRoute(Long id) {
        Route route = routeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Route introuvable avec l'ID : " + id));

        // 🔄 Dissocier les vendeurs
        for (Utilisateur vendeur : route.getVendeurs()) {
            vendeur.getRoutes().remove(route); // côté vendeur
        }
        route.getVendeurs().clear(); // côté route

        // 🔄 Dissocier les clients
        for (Client client : route.getClients()) {
            client.getRoutes().remove(route); // côté client
        }
        route.getClients().clear(); // côté route

        routeRepository.save(route); // Sauvegarder les dissociations

        // 🗑️ Supprimer la route
        routeRepository.delete(route);
    }
    @Transactional
    public void dissocierTousLesVendeurs(Long routeId) {
        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RuntimeException("Route introuvable avec l'ID : " + routeId));

        for (Utilisateur vendeur : route.getVendeurs()) {
            vendeur.getRoutes().remove(route);
        }
        route.getVendeurs().clear();
        routeRepository.save(route);
    }

    @Transactional
    public void dissocierTousLesClients(Long routeId) {
        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RuntimeException("Route introuvable avec l'ID : " + routeId));

        for (Client client : route.getClients()) {
            client.getRoutes().remove(route);
        }
        route.getClients().clear();
        routeRepository.save(route);
    }

}
