package com.example.backend.repository;

import com.example.backend.entity.PreVendeur;
import com.example.backend.entity.Superviseur;
import com.example.backend.entity.Utilisateur;
import com.example.backend.entity.VendeurDirect;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;


public interface UtilisateurRepository extends JpaRepository<Utilisateur, Long> {
    Optional<Utilisateur> findByNomUtilisateur(String nomUtilisateur);
    // Ajoutez cette méthode avec JOIN FETCH

    @Query("SELECT u FROM Utilisateur u LEFT JOIN FETCH u.superviseur")
    List<Utilisateur> findAllWithSuperviseur();

List<Utilisateur> findBySuperviseurId(Long superviseurId);
    // Trouver les pré-vendeurs supervisés par un superviseur donné
    // Trouver tous les pré-vendeurs qui ont ce superviseur
    @Query("SELECT v FROM VendeurDirect v WHERE v.superviseur = :superviseur")
    List<VendeurDirect> findVendeursBySuperviseur(@Param("superviseur") Superviseur superviseur);


    @Query("SELECT p FROM PreVendeur p WHERE p.superviseur = :superviseur")
    List<PreVendeur> findPreVendeursBySuperviseur(@Param("superviseur") Superviseur superviseur);



}

