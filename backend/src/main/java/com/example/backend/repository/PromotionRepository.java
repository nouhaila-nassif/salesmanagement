package com.example.backend.repository;

import com.example.backend.entity.CatégorieProduit;
import com.example.backend.entity.Promotion;
import com.example.backend.entity.TypePromotion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface PromotionRepository extends JpaRepository<Promotion, Long> {
    List<Promotion> findAllByDateDebutBeforeAndDateFinAfter(LocalDate dateDebut, LocalDate dateFin);
    List<Promotion> findByCategorie(CatégorieProduit categorie);
    @Query("SELECT p FROM Promotion p JOIN p.produits prod WHERE prod.id = :produitId")
    List<Promotion> findByProduitId(@Param("produitId") Long produitId);
    @Query("SELECT p FROM Promotion p WHERE p.type = 'CADEAU' AND p.produitCondition.nom = :nomProduit")
    List<Promotion> findPromoCadeauByProduitConditionNom(@Param("nomProduit") String nomProduit);
    List<Promotion> findAllByType(TypePromotion type);

    List<Promotion> findByTypeAndDateDebutLessThanEqualAndDateFinGreaterThanEqual(TypePromotion typePromotion, LocalDate now, LocalDate now1);
}
