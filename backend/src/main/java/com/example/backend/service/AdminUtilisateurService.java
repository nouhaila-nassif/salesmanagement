package com.example.backend.service;

import com.example.backend.dto.PreVendeurDTO;
import com.example.backend.dto.UpdateUtilisateurRequest;
import com.example.backend.dto.UtilisateurResponse;
import com.example.backend.dto.VendeurDirectDTO;
import com.example.backend.entity.*;
import com.example.backend.repository.*;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminUtilisateurService {
    @Autowired StockCamionRepository stockRepository;
@Autowired
private ClientRepository clientRepository;
    @Autowired
    private PreVendeurRepository preVendeurRepository;
@Autowired
private RouteRepository routeRepository;
    @Autowired
    private VendeurDirectRepository vendeurDirectRepository;
    @Autowired
    private VendeurRepository vendeurRepository;
    @Autowired
    private AdministrateurRepository adminRepository;

    @Autowired
    private CommandeRepository commandeRepository;

       private final UtilisateurRepository utilisateurRepo;
    private final PasswordEncoder passwordEncoder;
    private final UtilisateurRepository utilisateurRepository;
    private final StockCamionRepository stockCamionRepository;

    @Autowired
    private SuperviseurRepository superviseurRepository;

    @Autowired
    public AdminUtilisateurService(UtilisateurRepository utilisateurRepo, PasswordEncoder passwordEncoder,UtilisateurRepository utilisateurRepository, StockCamionRepository stockCamionRepository) {
        this.utilisateurRepo = utilisateurRepo;
        this.utilisateurRepository = utilisateurRepository;
        this.passwordEncoder = passwordEncoder;
        this.stockCamionRepository = stockCamionRepository;
    }
    public List<Utilisateur> getAllUtilisateurs() {
        return utilisateurRepository.findAll();
    }


    // ✅ Méthodes de création spécifiques selon le rôle

    public Utilisateur creerAdministrateur(String username, String password, String telephone, String email) {
        Administrateur admin = new Administrateur();
        admin.setNomUtilisateur(username);
        admin.setMotDePasseHash(passwordEncoder.encode(password));
        admin.setTelephone(telephone);
        admin.setEmail(email);
        return utilisateurRepo.save(admin);
    }


    @Transactional
    public VendeurDirectDTO creerVendeurDirect(String username, String password, Long superviseurId,
                                               String telephone, String email) {

        // 1. Vérification du superviseur
        Utilisateur superviseur = utilisateurRepo.findById(superviseurId)
                .orElseThrow(() -> new IllegalArgumentException("Superviseur non trouvé"));

        if (!"SUPERVISEUR".equalsIgnoreCase(superviseur.getRole())) {
            throw new IllegalArgumentException("L'ID ne correspond pas à un superviseur valide");
        }

        // 2. Création du vendeur direct
        VendeurDirect vendeur = new VendeurDirect();
        vendeur.setNomUtilisateur(username.trim());
        vendeur.setMotDePasseHash(passwordEncoder.encode(password));
        vendeur.setTelephone(telephone);
        vendeur.setEmail(email);
        vendeur.setSuperviseur(superviseur); // Lien superviseur crucial

        // Debug
        System.out.println("Création du vendeur avec superviseur : " + superviseur.getId());

        // 3. Sauvegarde
        VendeurDirect savedVendeur = utilisateurRepo.saveAndFlush(vendeur);

        // 4. Retourner le DTO
        return new VendeurDirectDTO(savedVendeur);
    }

    @Transactional
    public Superviseur creerSuperviseur(String username, String password, String telephone, String email) {
        // Vérification que le nom d'utilisateur n'existe pas déjà


        // Création de l'entité superviseur
        Superviseur superviseur = new Superviseur();
        superviseur.setNomUtilisateur(username.trim());
        superviseur.setMotDePasseHash(passwordEncoder.encode(password));
        superviseur.setTelephone(telephone);
        superviseur.setEmail(email);

        // Sauvegarde en base
        return utilisateurRepo.saveAndFlush(superviseur);
    }

    @Transactional
    public PreVendeurDTO creerPreVendeur(String username, String password, Long superviseurId,
                                         String telephone, String email) {

        Utilisateur superviseur = utilisateurRepo.findById(superviseurId)
                .orElseThrow(() -> new IllegalArgumentException("Superviseur non trouvé"));

        if (!"SUPERVISEUR".equalsIgnoreCase(superviseur.getRole())) {
            throw new IllegalArgumentException("L'ID ne correspond pas à un superviseur valide");
        }

        PreVendeur preVendeur = new PreVendeur();
        preVendeur.setNomUtilisateur(username.trim());
        preVendeur.setMotDePasseHash(passwordEncoder.encode(password));
        preVendeur.setTelephone(telephone);
        preVendeur.setEmail(email);

        // Sauvegarde initiale sans superviseur
        PreVendeur savedPreVendeur = utilisateurRepo.saveAndFlush(preVendeur);

        // Liaison superviseur et mise à jour
        savedPreVendeur.setSuperviseur(superviseur);

        // Si tu as besoin, faire un save pour appliquer la mise à jour
        savedPreVendeur = utilisateurRepo.saveAndFlush(savedPreVendeur);

        System.out.println("Pré-vendeur créé avec superviseur : " + superviseur.getId());

        return new PreVendeurDTO(savedPreVendeur);
    }

    @Transactional
    public void supprimerUtilisateurAvecReassignation(Long userId) {
        Utilisateur user = utilisateurRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Utilisateur avec ID " + userId + " introuvable"));

        if (user instanceof Superviseur superviseur) {
            // Détacher les PreVendeurs liés
            List<PreVendeur> preVendeurs = preVendeurRepository.findBySuperviseur(superviseur);
            for (PreVendeur pv : preVendeurs) {
                pv.setSuperviseur(null); // ou réassigner à un autre superviseur
                preVendeurRepository.save(pv);
            }

            // Détacher les VendeurDirect liés
            List<VendeurDirect> vendeurDirects = vendeurDirectRepository.findBySuperviseur(superviseur);
            for (VendeurDirect vd : vendeurDirects) {
                vd.setSuperviseur(null);
                vendeurDirectRepository.save(vd);
            }

            superviseurRepository.delete(superviseur);

        }
        else if (user instanceof VendeurDirect vendeurDirect) {
            Long vendeurId = vendeurDirect.getId();

            // Détacher les clients des routes
            List<Client> clients = clientRepository.findClientsByVendeurId(vendeurId);
            for (Client client : clients) {
                for (Route route : client.getRoutes()) {
                    route.getVendeurs().remove(vendeurDirect);
                    routeRepository.save(route);
                }
            }

            // Supprimer les commandes liées
            commandeRepository.dissocierCommandesDuVendeur(vendeurId);

            // Supprimer le stock lié
            stockRepository.supprimerStockParVendeur(vendeurId);

            // 1. Supprimer de la table `vendeur_direct`
            vendeurDirectRepository.deleteById(vendeurId);

            // 2. Supprimer de la table `vendeur` (intermédiaire dans l'héritage)
            vendeurRepository.deleteById(vendeurId); // Assure-toi que le repo existe

            // 3. Supprimer de la table `utilisateur`
            utilisateurRepository.deleteById(vendeurId);
        }

        else if (user instanceof PreVendeur preVendeur) {
            // Récupérer les routes associées au PreVendeur
            List<Route> routes = routeRepository.findByVendeursId(preVendeur.getId()); // méthode à créer si besoin

            // Récupérer les IDs des routes
            List<Long> routeIds = routes.stream().map(Route::getId).toList();

            // Récupérer les clients liés à ces routes
            List<Client> clients = clientRepository.findByRoutesIdIn(routeIds);

            // Pour chaque route, retirer le preVendeur des vendeurs
            for (Route route : routes) {
                route.getVendeurs().remove(preVendeur);
                routeRepository.save(route);
            }

            // Puis dissocier commandes liées au PreVendeur
            commandeRepository.dissocierCommandesDuVendeur(preVendeur.getId());

            // Supprimer le PreVendeur
            preVendeurRepository.delete(preVendeur);
        }

        else if (user instanceof Administrateur admin) {
            adminRepository.delete(admin);

        } else {
            throw new IllegalStateException("Type d'utilisateur non pris en charge : " + user.getClass().getSimpleName());
        }
    }

    public List<Utilisateur> getAllUsersWithSuperviseur() {
        return utilisateurRepository.findAllWithSuperviseur();
    }



    public Utilisateur modifierVendeurDirect(Long vendeurId, String nouveauUsername, String nouveauPassword, Long nouveauSuperviseurId) {
        // Rechercher le vendeur existant
        VendeurDirect vendeur = utilisateurRepo.findById(vendeurId)
                .filter(u -> u instanceof VendeurDirect)
                .map(u -> (VendeurDirect) u)
                .orElseThrow(() -> new IllegalArgumentException("Vendeur direct introuvable avec l'ID : " + vendeurId));

        // Mettre à jour le nom d'utilisateur si fourni
        if (nouveauUsername != null && !nouveauUsername.isEmpty()) {
            vendeur.setNomUtilisateur(nouveauUsername);
        }

        // Mettre à jour le mot de passe si fourni
        if (nouveauPassword != null && !nouveauPassword.isEmpty()) {
            vendeur.setMotDePasseHash(passwordEncoder.encode(nouveauPassword));
        }

        // Mettre à jour le superviseur si fourni
        if (nouveauSuperviseurId != null) {
            Superviseur nouveauSuperviseur = utilisateurRepo.findById(nouveauSuperviseurId)
                    .filter(u -> u instanceof Superviseur)
                    .map(u -> (Superviseur) u)
                    .orElseThrow(() -> new IllegalArgumentException("Superviseur introuvable avec l'ID : " + nouveauSuperviseurId));

            vendeur.setSuperviseur(nouveauSuperviseur);
        }

        // Sauvegarder les modifications
        return utilisateurRepo.save(vendeur);
    }





    public String genererContexteUtilisateurs() {
        List<Utilisateur> utilisateurs = utilisateurRepository.findAll();

        if (utilisateurs.isEmpty()) {
            return "Aucun utilisateur trouvé.";
        }

        StringBuilder contexte = new StringBuilder("Liste des utilisateurs :\n");

        for (Utilisateur u : utilisateurs) {
            String role = u.getRole() != null ? u.getRole() : "Rôle inconnu";
            String telephone = u.getTelephone() != null ? u.getTelephone() : "Téléphone inconnu";
            String email = u.getEmail() != null ? u.getEmail() : "Email inconnu";

            contexte.append("- [ID: ").append(u.getId()).append("] ")
                    .append(u.getNomUtilisateur())
                    .append(" | Rôle : ").append(role)
                    .append(" | Téléphone : ").append(telephone)
                    .append(" | Email : ").append(email);

            // ✅ Ajout du superviseur s'il existe
            if (u.getSuperviseur() != null) {
                contexte.append(" | Superviseur : ")
                        .append(u.getSuperviseur().getNomUtilisateur())
                        .append(" (ID: ").append(u.getSuperviseur().getId()).append(")");
            }

            contexte.append("\n");
        }

        return contexte.toString();
    }

    public Utilisateur modifierUtilisateur(Long id, UpdateUtilisateurRequest request) {
        Utilisateur existant = utilisateurRepo.findById(id)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

        // Nom d'utilisateur
        if (request.getNomUtilisateur() != null && !request.getNomUtilisateur().isBlank()) {
            existant.setNomUtilisateur(request.getNomUtilisateur().trim());
        }

        // Mot de passe (hashé)
        if (request.getMotDePasse() != null && !request.getMotDePasse().isEmpty()) {
            String motDePasseEncode = passwordEncoder.encode(request.getMotDePasse());
            existant.setMotDePasseHash(motDePasseEncode);
        }

        // Téléphone
        if (request.getTelephone() != null && !request.getTelephone().isBlank()) {
            existant.setTelephone(request.getTelephone().trim());
        }

        // Email
        if (request.getEmail() != null && !request.getEmail().isBlank()) {
            existant.setEmail(request.getEmail().trim());
        }

        // Superviseur (uniquement si l'utilisateur est VENDEURDIRECT ou PREVENDEUR)
        if ((request.getSuperviseurId() != null)
                && ("VENDEURDIRECT".equalsIgnoreCase(existant.getRole()) || "PREVENDEUR".equalsIgnoreCase(existant.getRole()))) {

            Utilisateur superviseur = utilisateurRepo.findById(request.getSuperviseurId())
                    .orElseThrow(() -> new IllegalArgumentException("Superviseur non trouvé"));

            if (!"SUPERVISEUR".equalsIgnoreCase(superviseur.getRole())) {
                throw new IllegalArgumentException("L'ID fourni ne correspond pas à un superviseur");
            }

            existant.setSuperviseur(superviseur);
        }

        return utilisateurRepo.save(existant);
    }




    public List<UtilisateurResponse> getAllPreVendeurs() {
        List<Utilisateur> utilisateurs = utilisateurRepository.findAll();

        return utilisateurs.stream()
                .filter(u -> u instanceof PreVendeur)
                .map(u -> new UtilisateurResponse((PreVendeur) u))
                .collect(Collectors.toList());
    }
    public List<UtilisateurResponse> getAllVendeurs() {
        List<Utilisateur> utilisateurs = utilisateurRepository.findAll();

        return utilisateurs.stream()
                .filter(u -> u instanceof VendeurDirect || u instanceof PreVendeur)
                .map(u -> {
                    if (u instanceof VendeurDirect) {
                        return new UtilisateurResponse((VendeurDirect) u);
                    } else {
                        return new UtilisateurResponse((PreVendeur) u);
                    }
                })
                .collect(Collectors.toList());
    }


    public Utilisateur getUtilisateur(Long id) {
        return utilisateurRepo.findById(id)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
    }
}
