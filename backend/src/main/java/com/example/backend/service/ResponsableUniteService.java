package com.example.backend.service;

import com.example.backend.entity.Administrateur;
import com.example.backend.entity.ResponsableUnite;
import com.example.backend.entity.Utilisateur;
import com.example.backend.repository.UtilisateurRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class ResponsableUniteService {

    @Autowired
    private UtilisateurRepository utilisateurRepository;

    @Autowired
    private PasswordEncoder encoder;

    // CREATE
    public ResponsableUnite createResponsableUnite(Utilisateur userRequesting, String username, String password) {
        if (!(userRequesting instanceof Administrateur)) {
            throw new RuntimeException("Seul un administrateur peut créer un responsable d’unité.");
        }

        ResponsableUnite responsable = new ResponsableUnite();
        responsable.setNomUtilisateur(username);
        responsable.setMotDePasseHash(encoder.encode(password));
        return utilisateurRepository.save(responsable);
    }

    // READ
    public List<ResponsableUnite> getAllResponsables() {
        return utilisateurRepository.findAll()
                .stream()
                .filter(u -> u instanceof ResponsableUnite)
                .map(u -> (ResponsableUnite) u)
                .toList();
    }

    public ResponsableUnite getResponsableById(Long id) {
        Utilisateur user = utilisateurRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Responsable non trouvé"));
        if (user instanceof ResponsableUnite) {
            return (ResponsableUnite) user;
        }
        throw new RuntimeException("L'utilisateur avec l'ID donné n'est pas un ResponsableUnite");
    }

    // UPDATE
    public ResponsableUnite updateResponsable(Long id, String username, String password) {
        ResponsableUnite responsable = getResponsableById(id);
        responsable.setNomUtilisateur(username);
        if (password != null && !password.isEmpty()) {
            responsable.setMotDePasseHash(encoder.encode(password));
        }
        return utilisateurRepository.save(responsable);
    }

    // DELETE
    public void deleteResponsable(Long id) {
        ResponsableUnite responsable = getResponsableById(id);
        utilisateurRepository.delete(responsable);
    }
}
