package com.example.backend.controller;

import com.example.backend.dto.CreateSuperviseurRequest;
import com.example.backend.entity.Administrateur;
import com.example.backend.entity.Superviseur;
import com.example.backend.entity.Utilisateur;
import com.example.backend.service.SuperviseurService;
import com.example.backend.service.UtilisateurService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/superviseur")
public class SuperviseurController {

    @Autowired
    private SuperviseurService superviseurService;

    @Autowired
    private UtilisateurService utilisateurService;

    private Utilisateur getCurrentAdmin() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        Utilisateur admin = utilisateurService.findByNomUtilisateur(username);

        if (!(admin instanceof Administrateur)) {
            throw new RuntimeException("Accès refusé : vous devez être un administrateur.");
        }

        return admin;
    }

    // CREATE
    @PostMapping("/create")
    public Superviseur createSuperviseur(@RequestBody CreateSuperviseurRequest request) {
        return superviseurService.createSuperviseur(
                getCurrentAdmin(),
                request.getUsername(),
                request.getPassword()
        );
    }

    // READ ALL
    @GetMapping
    public List<Superviseur> getAllSuperviseurs() {
        return superviseurService.getAllSuperviseurs();
    }

    // READ BY ID
    @GetMapping("/{id}")
    public Superviseur getSuperviseurById(@PathVariable Long id) {
        return superviseurService.getSuperviseurById(id);
    }

    // UPDATE
    @PutMapping("/{id}")
    public Superviseur updateSuperviseur(@PathVariable Long id, @RequestBody CreateSuperviseurRequest request) {
        return superviseurService.updateSuperviseur(id, request.getUsername(), request.getPassword());
    }

    // DELETE
    @DeleteMapping("/{id}")
    public void deleteSuperviseur(@PathVariable Long id) {
        superviseurService.deleteSuperviseur(id);
    }
}
