package com.example.backend.repository;

import com.example.backend.entity.PreVendeur;
import com.example.backend.entity.Superviseur;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface PreVendeurRepository extends JpaRepository<PreVendeur, Long> {
    List<PreVendeur> findBySuperviseur(Superviseur superviseur);
    @Query("SELECT p FROM PreVendeur p LEFT JOIN FETCH p.superviseur")
    List<PreVendeur> findAllWithSuperviseur();
    @EntityGraph(attributePaths = {"clients"})
    @Query("SELECT DISTINCT p FROM PreVendeur p")
    List<PreVendeur> findAllWithClients();
}
