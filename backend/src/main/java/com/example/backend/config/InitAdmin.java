package com.example.backend.config;

import com.example.backend.entity.Administrateur;
import com.example.backend.repository.UtilisateurRepository;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class InitAdmin {

    @Autowired
    private UtilisateurRepository utilisateurRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @PostConstruct
    public void init() {
        try {
            boolean adminExists = utilisateurRepository.findAll().stream()
                    .anyMatch(u -> u instanceof Administrateur);

            if (!adminExists) {
                Administrateur admin = new Administrateur();
                admin.setNomUtilisateur("admin");
                admin.setMotDePasseHash(passwordEncoder.encode("admin123"));

                utilisateurRepository.save(admin);
                System.out.println("✅ Administrateur créé.");
            } else {
                System.out.println("ℹ️ Un administrateur existe déjà.");
            }
        } catch (Exception e) {
            System.err.println("❌ Erreur lors de l'initialisation de l'administrateur : " + e.getMessage());
            e.printStackTrace();
        }
    }


}
