package com.example.backend.controller;

import com.example.backend.dto.CreateVendeurDirectRequest;
import com.example.backend.entity.Administrateur;
import com.example.backend.entity.Utilisateur;
import com.example.backend.entity.VendeurDirect;
import com.example.backend.service.UtilisateurService;
import com.example.backend.service.VendeurDirectService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/vendeurdirect")
public class VendeurDirectController {

    @Autowired
    private VendeurDirectService vendeurDirectService;

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
    public VendeurDirect createVendeurDirect(@RequestBody CreateVendeurDirectRequest request) {
        return vendeurDirectService.createVendeurDirect(
                getCurrentAdmin(),
                request.getNewVendeurDirectUsername(),
                request.getNewVendeurDirectPassword(),
                request.getSuperviseurId() // ✅ ajouter cette ligne pour passer l'ID du superviseur
        );
    }


    // READ all
    @GetMapping
    public List<VendeurDirect> getAll() {
        return vendeurDirectService.getAllVendeursDirects();
    }

    // READ by ID
    @GetMapping("/{id}")
    public VendeurDirect getById(@PathVariable Long id) {
        return vendeurDirectService.getVendeurDirectById(id);
    }

    // UPDATE
    @PutMapping("/{id}")
    public VendeurDirect update(@PathVariable Long id, @RequestBody CreateVendeurDirectRequest request) {
        return vendeurDirectService.updateVendeurDirect(
                id,
                request.getNewVendeurDirectUsername(),
                request.getNewVendeurDirectPassword()
        );
    }

    // DELETE
    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        vendeurDirectService.deleteVendeurDirect(id);
    }
}
