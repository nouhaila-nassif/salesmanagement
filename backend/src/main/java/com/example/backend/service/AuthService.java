package com.example.backend.service;

import com.example.backend.entity.Utilisateur;
import com.example.backend.repository.UtilisateurRepository;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class AuthService {

    private final UtilisateurRepository utilisateurRepo;

    public AuthService(UtilisateurRepository utilisateurRepo) {
        this.utilisateurRepo = utilisateurRepo;
    }

    // Méthode simple d'authentification : on cherche par nomUtilisateur et motDePasseHash (en clair pour l'exemple)
    public Optional<Utilisateur> authentifier(String nomUtilisateur, String motDePasse) {
        // Ici tu peux ajouter hash du mot de passe et comparaison
        return utilisateurRepo.findAll().stream()
                .filter(u -> u.getNomUtilisateur().equals(nomUtilisateur))
                .filter(u -> u.getMotDePasseHash().equals(motDePasse)) // en vrai => hash
                .findFirst();
    }
}
