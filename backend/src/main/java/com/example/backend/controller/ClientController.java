package com.example.backend.controller;

import com.example.backend.dto.ClientDTO;
import com.example.backend.dto.ClientResponseDTO;
import com.example.backend.dto.CreateClientRequest;
import com.example.backend.entity.Administrateur;
import com.example.backend.entity.Client;
import com.example.backend.entity.Utilisateur;
import com.example.backend.service.ClientService;
import com.example.backend.service.UtilisateurService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/client")
public class ClientController {

    @Autowired
    private ClientService clientService;

    @Autowired
    private UtilisateurService utilisateurService;

    // Méthode utilitaire pour récupérer l'utilisateur courant et vérifier s'il est admin
    private Utilisateur getCurrentAdmin() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        System.out.println("🔐 Utilisateur connecté : " + username);

        Utilisateur utilisateur = utilisateurService.findByNomUtilisateur(username);
        if (utilisateur == null) {
            throw new RuntimeException("Utilisateur non trouvé : " + username);
        }

        if (!(utilisateur instanceof Administrateur)) {
            throw new RuntimeException("Accès refusé : seul un administrateur peut gérer les clients.");
        }
        return utilisateur;
    }
    // 🔓 Accessible par les vendeurs connectés
    @GetMapping("/mes-clients")
    public List<ClientDTO> getClientsForCurrentVendeur() {
        Utilisateur utilisateur = getCurrentUser(); // méthode pour récupérer l'utilisateur connecté

        List<Client> clients;

        // Si admin, retourner tous les clients
        if (utilisateur instanceof Administrateur || "ADMIN".equals(utilisateur.getRole())) {
            clients = clientService.getAllClients();
        }
        // Si vendeur ou pré-vendeur, retourner seulement ses clients
        else if ("VENDEURDIRECT".equals(utilisateur.getRole()) || "PREVENDEUR".equals(utilisateur.getRole())) {
            clients = clientService.getClientsByVendeur(utilisateur.getId());
        }
        else {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Accès réservé aux vendeurs et pré-vendeurs");
        }

        // Convertir en DTO avec routes simplifiées
        return clients.stream()
                .map(ClientDTO::new) // constructeur de ClientDTO qui fait le mapping complet
                .collect(Collectors.toList());
    }

    @GetMapping("/mes-clients/{id}")
    public ClientDTO getClientById(@PathVariable Long id) {
        Utilisateur utilisateur = getCurrentUser(); // récupérer l'utilisateur connecté

        List<Client> clients;

        // Selon le rôle, récupérer les clients autorisés
        if (utilisateur instanceof Administrateur || "ADMIN".equals(utilisateur.getRole())) {
            clients = clientService.getAllClients();
        } else if ("VENDEURDIRECT".equals(utilisateur.getRole()) || "PREVENDEUR".equals(utilisateur.getRole())) {
            clients = clientService.getClientsByVendeur(utilisateur.getId());
        } else {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Accès réservé aux vendeurs et pré-vendeurs");
        }

        // Chercher le client par id dans la liste filtrée
        Client client = clients.stream()
                .filter(c -> c.getId().equals(id))
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Client non trouvé"));

        return new ClientDTO(client);
    }


    // 🔐 Méthode utilitaire pour récupérer n'importe quel utilisateur connecté
    private Utilisateur getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        Utilisateur utilisateur = utilisateurService.findByNomUtilisateur(username);
        if (utilisateur == null) {
            throw new RuntimeException("Utilisateur non trouvé : " + username);
        }
        return utilisateur;
    }

    // 🔒 Créer un client - Admin seulement
    @PostMapping("/create")
    public ClientResponseDTO createClient(@RequestBody CreateClientRequest request) {
        getCurrentAdmin();
        Client client = clientService.createClient(request.toClient(), request.getRouteId());
        return new ClientResponseDTO(client);
    }


    // 🟢 Obtenir la liste des clients - Accessible à tout utilisateur connecté
    @GetMapping("/clients")
    public ResponseEntity<List<ClientDTO>> getAllClients() {
        List<Client> clients = clientService.getAllClients();
        List<ClientDTO> dtos = clients.stream()
                .map(ClientDTO::new) // constructeur qui convertit Client en ClientDTO avec RouteNomDTO
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }


    // 🟢 Obtenir un client par ID - Accessible à tout utilisateur connecté


    // 🔒 Modifier un client - Admin seulement
    @PutMapping("/{id}")
    public Client updateClient(@PathVariable Long id, @RequestBody CreateClientRequest request) {
        getCurrentAdmin(); // Vérification rôle admin
        return clientService.updateClient(id, request.toClient(), request.getRouteId());
    }
    // 🔓 Accessible par les vendeurs connectés



    // 🔒 Supprimer un client - Admin seulement
    @DeleteMapping("/{id}")
    public void deleteClient(@PathVariable Long id) {
        getCurrentAdmin(); // Vérification rôle admin
        clientService.deleteClient(id);
    }
}
