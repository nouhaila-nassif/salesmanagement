package com.example.backend.service;

import com.example.backend.entity.*;
import com.example.backend.repository.UtilisateurRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class UtilisateurService {

    private final UtilisateurRepository utilisateurRepository;
    private final PasswordEncoder passwordEncoder;
    public Utilisateur findById(Long id) {
        // Exemple d'implémentation
        return utilisateurRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Utilisateur non trouvé avec l'id : " + id));
    }
    public Utilisateur getVendeurParDefaut() {
        // Récupérer tous les utilisateurs, filtrer ceux qui sont des vendeurs
        List<Utilisateur> utilisateurs = utilisateurRepository.findAll();

        for (Utilisateur u : utilisateurs) {
            if (u instanceof Vendeur) {
                return u;  // retourne le premier utilisateur qui est un Vendeur
            }
        }
        return null; // aucun vendeur trouvé
    }

    // Injection par constructeur (automatique avec Spring Boot)
    public UtilisateurService(UtilisateurRepository utilisateurRepository,
                              PasswordEncoder passwordEncoder) {
        this.utilisateurRepository = utilisateurRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public List<Utilisateur> findAllVendeurs() {
        return utilisateurRepository.findAll().stream()
                .filter(user -> user instanceof PreVendeur || user instanceof VendeurDirect || (
                        !(user instanceof Superviseur) &&
                                !(user instanceof Administrateur) &&
                                !(user instanceof ResponsableUnite)
                ))
                .collect(Collectors.toList());
    }

    public List<Utilisateur> getAllUtilisateurs() {
        return utilisateurRepository.findAll();
    }

    public List<Superviseur> findAllSuperviseurs() {
        return utilisateurRepository.findAll()
                .stream()
                .filter(u -> u instanceof Superviseur)
                .map(u -> (Superviseur) u)
                .collect(Collectors.toList());
    }


    public Utilisateur findByNomUtilisateur(String nomUtilisateur) {
        return utilisateurRepository.findByNomUtilisateur(nomUtilisateur).orElse(null);
    }

    public Utilisateur getUtilisateurActuel() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null || !authentication.isAuthenticated()) {
            throw new RuntimeException("Aucun utilisateur authentifié");
        }

        String nomUtilisateur = authentication.getName();
        return utilisateurRepository.findByNomUtilisateur(nomUtilisateur)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
    }

    public Utilisateur getUtilisateur(String username) {
        return utilisateurRepository.findByNomUtilisateur(username)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
    }

    public Utilisateur login(String username, String password) {
        Utilisateur utilisateur = utilisateurRepository.findByNomUtilisateur(username)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

        if (!passwordEncoder.matches(password, utilisateur.getMotDePasseHash())) {
            throw new RuntimeException("Mot de passe incorrect");
        }

        return utilisateur;
    }

}
