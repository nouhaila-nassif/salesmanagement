package com.example.backend.repository;

import com.example.backend.entity.Vendeur;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VendeurRepository extends JpaRepository<Vendeur, Long> {
    // Méthode existante (automatiquement implémentée par Spring Data JPA)
    List<Vendeur> findAllById(Iterable<Long> ids);

}