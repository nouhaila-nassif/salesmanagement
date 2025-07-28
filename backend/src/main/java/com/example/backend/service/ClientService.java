package com.example.backend.service;

import com.example.backend.entity.*;
import com.example.backend.repository.ClientRepository;
import com.example.backend.repository.CommandeRepository;
import com.example.backend.repository.RouteRepository;
import com.example.backend.repository.VisiteRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class ClientService {
    @Autowired
    private UtilisateurService utilisateurService;
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
    private Utilisateur getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        Utilisateur utilisateur = utilisateurService.findByNomUtilisateur(username);
        if (utilisateur == null) {
            throw new RuntimeException("Utilisateur non trouvé : " + username);
        }
        return utilisateur;
    }

    public List<Client> getClientsByVendeur(Long vendeurId) {
        return clientRepository.findClientsByVendeurId(vendeurId);
    }

    public String genererContexteClients() {
        Utilisateur utilisateur = getCurrentUser(); // méthode pour récupérer l'utilisateur connecté

        List<Client> clients;

        // Récupération des clients en fonction du rôle
        if (utilisateur instanceof Administrateur || "ADMIN".equals(utilisateur.getRole())) {
            clients = getAllClientsWithDetails(); // avec fetch relations
        } else if ("VENDEURDIRECT".equals(utilisateur.getRole()) || "PREVENDEUR".equals(utilisateur.getRole())) {
            clients = getClientsByVendeur(utilisateur.getId());
        } else {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Accès réservé aux vendeurs et administrateurs");
        }

        if (clients.isEmpty()) {
            return "Aucun client disponible pour cet utilisateur.";
        }

        StringBuilder contexte = new StringBuilder("Voici la liste des clients et leurs informations :\n");

        for (Client client : clients) {
            contexte.append("- [ID: ").append(client.getId()).append("] ")
                    .append("Client : ").append(client.getNom());

            if (client.getType() != null) {
                contexte.append(" (Type : ").append(client.getType()).append(")");
            }
            if (client.getTelephone() != null) {
                contexte.append(", Téléphone : ").append(client.getTelephone());
            }
            if (client.getEmail() != null) {
                contexte.append(", Email : ").append(client.getEmail());
            }
            if (client.getAdresse() != null) {
                contexte.append(", Adresse : ").append(client.getAdresse());
            }
            if (client.getDerniereVisite() != null) {
                contexte.append(", Dernière visite : ").append(client.getDerniereVisite().toString());
            }

            // Routes associées
            if (client.getRoutes() != null && !client.getRoutes().isEmpty()) {
                String routes = client.getRoutes().stream()
                        .map(Route::getNom)
                        .collect(Collectors.joining(", "));
                contexte.append(", Routes : ").append(routes);
            }

            // Commandes récentes
            List<Commande> commandes = commandeRepository.findTop3ByClientIdOrderByDateCreationDesc(client.getId());
            if (!commandes.isEmpty()) {
                contexte.append(", Commandes récentes : ");
                String commandesStr = commandes.stream()
                        .map(cmd -> {
                            String date = cmd.getDateCreation() != null ? cmd.getDateCreation().toString() : "Date inconnue";
                            String montant = cmd.getMontantTotal() != null ? String.format("%.2f DH", cmd.getMontantTotal()) : "Montant inconnu";
                            return "[" + date + " : " + montant + "]";
                        })
                        .collect(Collectors.joining(", "));
                contexte.append(commandesStr);
            }

            // Visites récentes
            List<Visite> visites = visiteRepository.findTop2ByClientIdOrderByDatePlanifieeDesc(client.getId());
            if (!visites.isEmpty()) {
                contexte.append(", Visites récentes : ");
                String visitesStr = visites.stream()
                        .map(visite -> visite.getDatePlanifiee() != null ? visite.getDatePlanifiee().toString() : "Date inconnue")
                        .collect(Collectors.joining(", "));
                contexte.append(visitesStr);
            }

            contexte.append("\n");
        }

        return contexte.toString();
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
