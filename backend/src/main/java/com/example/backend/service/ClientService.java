package com.example.backend.service;

import com.example.backend.entity.*;
import com.example.backend.repository.ClientRepository;
import com.example.backend.repository.CommandeRepository;
import com.example.backend.repository.RouteRepository;
import com.example.backend.repository.VisiteRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class ClientService {

    private final ClientRepository clientRepository;
    private final CommandeRepository commandeRepository;
    private final VisiteRepository visiteRepository;
    private final RouteRepository routeRepository;

    @Autowired
    public ClientService(ClientRepository clientRepository,
                         CommandeRepository commandeRepository,
                         VisiteRepository visiteRepository,
                         RouteRepository routeRepository) {
        this.clientRepository = clientRepository;
        this.commandeRepository = commandeRepository;
        this.visiteRepository = visiteRepository;
        this.routeRepository = routeRepository;
    }
    // CREATE
    @Transactional
    public Client createClient(Client client, Long routeId) {
        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new RuntimeException("Route non trouvée avec l'ID : " + routeId));

        // ⚠️ Vérifie si le client a déjà une liste de routes, sinon crée-la
        if (client.getRoutes() == null) {
            client.setRoutes(new HashSet<>());
        }

        // 🔁 Ajouter la route au client
        client.getRoutes().add(route);

        // 💬 Optionnel : ajouter le client à la route aussi (si bidirectionnel)
        route.getClients().add(client);

        return clientRepository.save(client);
    }

    public List<Client> getClientsByVendeur(Long vendeurId) {
        return clientRepository.findClientsByVendeurId(vendeurId);
    }


    public List<Client> getAllClientsWithDetails() {
        return clientRepository.findAllWithDetails();
    }
    // READ
    public List<Client> getAllClients() {
        return clientRepository.findAll(); // Supposant que vous utilisez JPA
    }

    public Client getClientById(Long id) {
        return clientRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Client non trouvé"));
    }

    // UPDATE
    @Transactional
    public Client updateClient(Long id, Client updatedClient, Long routeId) {
        Client existing = clientRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Client non trouvé"));

        // Mise à jour des champs simples
        existing.setNom(updatedClient.getNom());
        existing.setTelephone(updatedClient.getTelephone());
        existing.setEmail(updatedClient.getEmail());
        existing.setAdresse(updatedClient.getAdresse());
        existing.setType(updatedClient.getType());
        existing.setDerniereVisite(updatedClient.getDerniereVisite());

        // Mise à jour des routes (relation ManyToMany)
        if (routeId != null) {
            Route route = routeRepository.findById(routeId)
                    .orElseThrow(() -> new RuntimeException("Route non trouvée avec l'ID : " + routeId));

            // Initialise si null
            if (existing.getRoutes() == null) {
                existing.setRoutes(new HashSet<>());
            }

            // Ajoute la route s'il n'y est pas déjà
            existing.getRoutes().add(route);
            route.getClients().add(existing); // si relation bidirectionnelle
        }

        return clientRepository.save(existing);
    }
    public Client findById(Long id) {
        Optional<Client> client = clientRepository.findById(id);
        return client.orElse(null);
    }


    @Transactional
    public void deleteClient(Long id) {
        Client client = clientRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Client non trouvé avec id: " + id));

        // Pour chaque route associée, retirer le client de la liste clients
        for (Route route : client.getRoutes()) {
            route.getClients().remove(client);
        }

        // Vider la collection routes côté client
        client.getRoutes().clear();

        // Sauvegarder les routes mises à jour
        routeRepository.saveAll(client.getRoutes());

        // Sauvegarder le client
        clientRepository.save(client);

        // Supprimer le client
        clientRepository.deleteById(id);
    }

}
