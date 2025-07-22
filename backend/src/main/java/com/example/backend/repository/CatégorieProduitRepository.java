package com.example.backend.repository;

import com.example.backend.entity.CatégorieProduit;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;


public interface CatégorieProduitRepository extends JpaRepository<CatégorieProduit, Long> {
    Optional<CatégorieProduit> findByNom(String nom);

}
