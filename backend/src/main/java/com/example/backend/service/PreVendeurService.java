package com.example.backend.service;

import com.example.backend.entity.*;
import com.example.backend.repository.CommandeRepository;
import com.example.backend.repository.PreVendeurRepository;
import com.example.backend.repository.UtilisateurRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class PreVendeurService {

    @Autowired
    private UtilisateurRepository utilisateurRepository;
    @Autowired
    private CommandeRepository commandeRepository;
    @Autowired
    private PreVendeurRepository preVendeurRepository;
    @Autowired
    private PasswordEncoder encoder;
    public List<PreVendeur> getAllPreVendeursWithClients() {
        return preVendeurRepository.findAllWithClients();
    }
    public PreVendeur createPreVendeur(Utilisateur userRequesting, String username, String password, String telephone, String email) {
        if (!(userRequesting instanceof Administrateur)) {
            throw new RuntimeException("Seul un administrateur peut créer un pré-vendeur.");
        }

        PreVendeur preVendeur = new PreVendeur();
        preVendeur.setNomUtilisateur(username);
        preVendeur.setMotDePasseHash(encoder.encode(password));
        preVendeur.setTelephone(telephone);
        preVendeur.setEmail(email);

        return utilisateurRepository.save(preVendeur);
    }

    public List<PreVendeur> getAllPreVendeurs() {
        return utilisateurRepository.findAll()
                .stream()
                .filter(u -> u instanceof PreVendeur)
                .map(u -> (PreVendeur) u)
                .collect(Collectors.toList());
    }

    public PreVendeur getPreVendeurById(Long id) {
        Utilisateur utilisateur = utilisateurRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Pré-vendeur non trouvé"));

        if (!(utilisateur instanceof PreVendeur)) {
            throw new RuntimeException("L'utilisateur trouvé n'est pas un pré-vendeur");
        }

        return (PreVendeur) utilisateur;
    }

    public PreVendeur updatePreVendeur(Long id, String username, String password, String telephone, String email) {
        PreVendeur preVendeur = getPreVendeurById(id); // récupère ou lève exception

        preVendeur.setNomUtilisateur(username);

        if (password != null && !password.isEmpty()) {
            preVendeur.setMotDePasseHash(encoder.encode(password));
        }

        preVendeur.setTelephone(telephone);
        preVendeur.setEmail(email);

        return utilisateurRepository.save(preVendeur);
    }

    @Transactional
    public void supprimerPreVendeur(Long preVendeurId) {
        PreVendeur preVendeur = utilisateurRepository.findById(preVendeurId)
                .filter(u -> u instanceof PreVendeur)
                .map(u -> (PreVendeur) u)
                .orElseThrow(() -> new IllegalArgumentException("Pré-vendeur introuvable avec l'ID : " + preVendeurId));

        // Dissocier les commandes du pré-vendeur
        List<Commande> commandes = commandeRepository.findByVendeurId(preVendeurId);
        for (Commande commande : commandes) {
            commande.setVendeur(null); // ou attribuer à un autre utilisateur si nécessaire
        }
        commandeRepository.saveAll(commandes);

        // Supprimer les routes associées au vendeur
        for (Route route : new HashSet<>(preVendeur.getRoutes())) {
            route.getVendeurs().remove(preVendeur);
        }
        preVendeur.getRoutes().clear();
        utilisateurRepository.save(preVendeur);

        // Supprimer le pré-vendeur
        utilisateurRepository.delete(preVendeur);
    }

}
