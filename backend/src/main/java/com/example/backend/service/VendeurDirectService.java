package com.example.backend.service;

import com.example.backend.entity.Administrateur;
import com.example.backend.entity.Superviseur;
import com.example.backend.entity.Utilisateur;
import com.example.backend.entity.VendeurDirect;
import com.example.backend.repository.UtilisateurRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class VendeurDirectService {

    @Autowired
    private UtilisateurRepository utilisateurRepository;
    private final PasswordEncoder passwordEncoder;

    @Autowired
    private PasswordEncoder encoder;
    @Autowired
    public VendeurDirectService(PasswordEncoder passwordEncoder) {
        this.passwordEncoder = passwordEncoder;
    }
    // CREATE
    public VendeurDirect createVendeurDirect(Utilisateur admin, String username, String password, Long superviseurId) {
        VendeurDirect vendeur = new VendeurDirect();
        vendeur.setNomUtilisateur(username);
        vendeur.setMotDePasseHash(encoder.encode(password));

        // Affecter le superviseur
        Superviseur superviseur = utilisateurRepository.findById(superviseurId)
                .filter(u -> u instanceof Superviseur)
                .map(u -> (Superviseur) u)
                .orElseThrow(() -> new IllegalArgumentException("Superviseur introuvable avec ID : " + superviseurId));
        vendeur.setSuperviseur(superviseur);

        // Autres logiques (assignation d’unité, validation par admin, etc.)

        return utilisateurRepository.save(vendeur);
    }

    // READ
    public List<VendeurDirect> getAllVendeursDirects() {
        return utilisateurRepository.findAll().stream()
                .filter(u -> u instanceof VendeurDirect)
                .map(u -> (VendeurDirect) u)
                .toList();
    }

    public VendeurDirect getVendeurDirectById(Long id) {
        Utilisateur user = utilisateurRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Vendeur direct non trouvé"));
        if (user instanceof VendeurDirect vendeur) {
            return vendeur;
        }
        throw new RuntimeException("L'utilisateur avec l'ID donné n'est pas un VendeurDirect");
    }

    // UPDATE
    public VendeurDirect updateVendeurDirect(Long id, String username, String password) {
        VendeurDirect vendeur = getVendeurDirectById(id);
        vendeur.setNomUtilisateur(username);
        if (password != null && !password.isEmpty()) {
            vendeur.setMotDePasseHash(encoder.encode(password));
        }
        return utilisateurRepository.save(vendeur);
    }

    // DELETE
    public void deleteVendeurDirect(Long id) {
        VendeurDirect vendeur = getVendeurDirectById(id);
        utilisateurRepository.delete(vendeur);
    }
}
