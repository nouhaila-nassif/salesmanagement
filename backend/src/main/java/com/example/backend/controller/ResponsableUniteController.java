package com.example.backend.controller;

import com.example.backend.dto.CreateResponsableUniteRequest;
import com.example.backend.entity.Administrateur;
import com.example.backend.entity.ResponsableUnite;
import com.example.backend.entity.Utilisateur;
import com.example.backend.service.ResponsableUniteService;
import com.example.backend.service.UtilisateurService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/responsable-unite")
public class ResponsableUniteController {

    @Autowired
    private ResponsableUniteService service;

    @Autowired
    private UtilisateurService utilisateurService;

    private Utilisateur getCurrentAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();  // username est une String
        Utilisateur user = utilisateurService.findByNomUtilisateur(username);
        if (!(user instanceof Administrateur)) {
            throw new RuntimeException("Accès refusé : vous devez être un administrateur.");
        }
        return user;
    }


    @PostMapping("/create")
    public ResponsableUnite create(@RequestBody CreateResponsableUniteRequest request) {
        return service.createResponsableUnite(getCurrentAdmin(), request.getUsername(), request.getPassword());
    }

    @GetMapping
    public List<ResponsableUnite> getAll() {
        return service.getAllResponsables();
    }

    @GetMapping("/{id}")
    public ResponsableUnite getById(@PathVariable Long id) {
        return service.getResponsableById(id);
    }

    @PutMapping("/{id}")
    public ResponsableUnite update(@PathVariable Long id, @RequestBody CreateResponsableUniteRequest request) {
        return service.updateResponsable(id, request.getUsername(), request.getPassword());
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        service.deleteResponsable(id);
    }
}
