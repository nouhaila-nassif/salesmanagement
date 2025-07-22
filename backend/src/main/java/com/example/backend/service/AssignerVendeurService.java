package com.example.backend.service;

import com.example.backend.entity.*;
import com.example.backend.repository.UtilisateurRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.lang.reflect.Field;

@Service
public class AssignerVendeurService {

    private final UtilisateurRepository utilisateurRepo;

    @Autowired
    public AssignerVendeurService(UtilisateurRepository utilisateurRepo) {
        this.utilisateurRepo = utilisateurRepo;
    }

    public Utilisateur assignerVendeur(Long vendeurId, Long superviseurId) {
        Utilisateur vendeur = utilisateurRepo.findById(vendeurId)
                .orElseThrow(() -> new RuntimeException("Vendeur non trouvé"));
        Utilisateur superviseur = utilisateurRepo.findById(superviseurId)
                .orElseThrow(() -> new RuntimeException("Superviseur non trouvé"));

        if (!(vendeur instanceof PreVendeur || vendeur instanceof VendeurDirect)) {
            throw new RuntimeException("L'utilisateur n'est pas un vendeur valide");
        }

        if (!(superviseur instanceof Superviseur)) {
            throw new RuntimeException("Le responsable doit être un Superviseur");
        }

        try {
            Field superviseurField = vendeur.getClass().getDeclaredField("superviseur");
            superviseurField.setAccessible(true);
            superviseurField.set(vendeur, superviseur);
        } catch (NoSuchFieldException | IllegalAccessException e) {
            throw new RuntimeException("Erreur d'assignation par réflexion", e);
        }

        return utilisateurRepo.save(vendeur);
    }

}
