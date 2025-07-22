package com.example.backend.repository;

import com.example.backend.entity.StockCamion;
import com.example.backend.entity.VendeurDirect;
import jakarta.transaction.Transactional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
@Repository
public interface StockCamionRepository extends JpaRepository<StockCamion, Long> {
    @Modifying
    @Transactional
    @Query("UPDATE Commande c SET c.vendeur = null WHERE c.vendeur.id = :vendeurId")
    void dissocierCommandesDuVendeur(@Param("vendeurId") Long vendeurId);
    @Modifying
    @Transactional
    @Query("DELETE FROM StockCamion s WHERE s.chauffeur.id = :vendeurId")
    void supprimerStockParVendeur(@Param("vendeurId") Long vendeurId);


    // Trouver un stock par le vendeur direct (chauffeur)
    Optional<StockCamion> findByChauffeur(VendeurDirect chauffeur);
    // Exemple dans StockCamionRepository
    List<StockCamion> findByChauffeurId(Long chauffeurId);

    // Trouver un stock par l’ID du vendeur direct (chauffeur)
}
