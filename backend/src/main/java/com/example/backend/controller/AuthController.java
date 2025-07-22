package com.example.backend.controller;

import com.example.backend.dto.LoginRequest;
import com.example.backend.entity.Utilisateur;
import com.example.backend.repository.UtilisateurRepository;
import com.example.backend.security.JwtUtil;
import com.example.backend.service.UtilisateurService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtUtil jwtUtil;
    @Autowired
    private UtilisateurRepository utilisateurRepository;
    @Autowired
    private UtilisateurService utilisateurService;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        // Authentification
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getNomUtilisateur(), request.getMotDePasse())
        );

        // Récupérer l'utilisateur
        Utilisateur user = utilisateurRepository.findByNomUtilisateur(request.getNomUtilisateur())
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

        // Générer le token avec rôle
        String token = jwtUtil.generateToken(user.getNomUtilisateur(), user.getRole());

        // Retourner token + rôle
        return ResponseEntity.ok(Map.of(
                "token", token,
                "role", user.getRole()
        ));
    }
}
