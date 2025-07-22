package com.example.backend.service;

import com.example.backend.entity.Administrateur;
import com.example.backend.entity.Superviseur;
import com.example.backend.entity.Utilisateur;
import com.example.backend.repository.UtilisateurRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class SuperviseurService {

    @Autowired
    private UtilisateurRepository utilisateurRepository;

    @Autowired
    private PasswordEncoder encoder;

    // CREATE
    public Superviseur createSuperviseur(Utilisateur admin, String username, String password) {
        if (!(admin instanceof Administrateur)) {
            throw new RuntimeException("Seul un administrateur peut créer un superviseur.");
        }

        Superviseur superviseur = new Superviseur();
        superviseur.setNomUtilisateur(username);
        superviseur.setMotDePasseHash(encoder.encode(password));
        return utilisateurRepository.save(superviseur);
    }

    // READ ALL
    public List<Superviseur> getAllSuperviseurs() {
        return utilisateurRepository.findAll().stream()
                .filter(u -> u instanceof Superviseur)
                .map(u -> (Superviseur) u)
                .toList();
    }

    // READ BY ID
    public Superviseur getSuperviseurById(Long id) {
        Utilisateur user = utilisateurRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Superviseur non trouvé"));
        if (user instanceof Superviseur superviseur) {
            return superviseur;
        }
        throw new RuntimeException("L'utilisateur avec cet ID n'est pas un superviseur.");
    }

    // UPDATE
    public Superviseur updateSuperviseur(Long id, String username, String password) {
        Superviseur superviseur = getSuperviseurById(id);
        superviseur.setNomUtilisateur(username);
        if (password != null && !password.isEmpty()) {
            superviseur.setMotDePasseHash(encoder.encode(password));
        }
        return utilisateurRepository.save(superviseur);
    }

    // DELETE
    public void deleteSuperviseur(Long id) {
        Superviseur superviseur = getSuperviseurById(id);
        utilisateurRepository.delete(superviseur);
    }
}
