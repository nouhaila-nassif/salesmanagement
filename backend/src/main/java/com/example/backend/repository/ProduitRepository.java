package com.example.backend.repository;

import com.example.backend.entity.Produit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;


@Repository
public interface ProduitRepository extends JpaRepository<Produit, Long> {
    Optional<Produit> findByNom(String nom);
    @Query("SELECT p FROM Produit p WHERE LOWER(TRIM(p.nom)) = LOWER(TRIM(:nom))")
    Optional<Produit> findByNomIgnoreCaseAndTrimmed(@Param("nom") String nom);

    @Query("SELECT p FROM Produit p LEFT JOIN FETCH p.promotions WHERE p.id = :id")
    Optional<Produit> findByIdWithPromotions(@Param("id") Long id);

}
