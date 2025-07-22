package com.example.backend.controller;

import com.example.backend.dto.CreatePreVendeurRequest;
import com.example.backend.entity.Administrateur;
import com.example.backend.entity.PreVendeur;
import com.example.backend.entity.Utilisateur;
import com.example.backend.service.PreVendeurService;
import com.example.backend.service.UtilisateurService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/prevendeur")
public class PreVendeurController {

    @Autowired
    private PreVendeurService preVendeurService;

    @Autowired
    private UtilisateurService utilisateurService;

    private Utilisateur getCurrentAdmin() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String adminUsername = authentication.getName();
        Utilisateur admin = utilisateurService.findByNomUtilisateur(adminUsername);
        if (!(admin instanceof Administrateur)) {
            throw new RuntimeException("Accès refusé : vous devez être un administrateur.");
        }
        return admin;
    }

    @PostMapping("/create")
    public PreVendeur createPreVendeur(@RequestBody CreatePreVendeurRequest request) {
        return preVendeurService.createPreVendeur(
                getCurrentAdmin(),
                request.getNewPreVendeurUsername(),
                request.getNewPreVendeurPassword(),
                request.getTelephone(),
                request.getEmail()
        );
    }

    @GetMapping
    public List<PreVendeur> getAllPreVendeurs() {
        return preVendeurService.getAllPreVendeurs();
    }

    @GetMapping("/{id}")
    public PreVendeur getPreVendeurById(@PathVariable Long id) {
        return preVendeurService.getPreVendeurById(id);
    }

    @PutMapping("/{id}")
    public PreVendeur updatePreVendeur(@PathVariable Long id, @RequestBody CreatePreVendeurRequest request) {
        return preVendeurService.updatePreVendeur(
                id,
                request.getNewPreVendeurUsername(),
                request.getNewPreVendeurPassword(),
                request.getTelephone(),
                request.getEmail()
        );
    }

    @DeleteMapping("/{id}")
    public void deletePreVendeur(@PathVariable Long id) {
        preVendeurService.supprimerPreVendeur(id);
    }
}
