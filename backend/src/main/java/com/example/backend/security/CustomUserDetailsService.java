package com.example.backend.security;

import com.example.backend.entity.Administrateur;
import com.example.backend.entity.ResponsableUnite;
import com.example.backend.entity.Superviseur;
import com.example.backend.entity.Utilisateur;
import com.example.backend.repository.UtilisateurRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private final UtilisateurRepository utilisateurRepository;

    @Autowired
    public CustomUserDetailsService(UtilisateurRepository utilisateurRepository) {
        this.utilisateurRepository = utilisateurRepository;
    }
    public String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication != null && authentication.isAuthenticated()) {
            Object principal = authentication.getPrincipal();

            if (principal instanceof UserDetails) {
                return ((UserDetails) principal).getUsername();
            } else {
                return principal.toString(); // En cas de login par token ou autre
            }
        }

        return null;
    }
    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String nomUtilisateur) throws UsernameNotFoundException {
        Utilisateur utilisateur = utilisateurRepository.findByNomUtilisateur(nomUtilisateur)
                .orElseThrow(() -> new UsernameNotFoundException("Aucun utilisateur trouvé avec le nom: " + nomUtilisateur));

        return new org.springframework.security.core.userdetails.User(
                utilisateur.getNomUtilisateur(),
                utilisateur.getMotDePasseHash(),
                true, true, true, true, // enabled, accountNonExpired, credentialsNonExpired, accountNonLocked
                getAuthorities(utilisateur)
        );
    }

    private List<GrantedAuthority> getAuthorities(Utilisateur utilisateur) {
        List<GrantedAuthority> authorities = new ArrayList<>();

        // Ajout des rôles selon le type d'utilisateur
        if (utilisateur instanceof Administrateur) {
            authorities.add(new SimpleGrantedAuthority("ROLE_ADMIN"));
            authorities.add(new SimpleGrantedAuthority("ADMIN_PRIVILEGE"));
        } else if (utilisateur instanceof Superviseur) {
            authorities.add(new SimpleGrantedAuthority("ROLE_SUPERVISEUR"));
            authorities.add(new SimpleGrantedAuthority("SUPERVISEUR_PRIVILEGE"));
        } else if (utilisateur instanceof ResponsableUnite) {
            authorities.add(new SimpleGrantedAuthority("ROLE_RESPONSABLE"));
            authorities.add(new SimpleGrantedAuthority("RESPONSABLE_PRIVILEGE"));
        }
        // Ajouter d'autres rôles au besoin

        return authorities;
    }
}