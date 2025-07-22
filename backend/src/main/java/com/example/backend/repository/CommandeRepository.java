package com.example.backend.repository;

import com.example.backend.entity.Commande;
import jakarta.transaction.Transactional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface CommandeRepository extends JpaRepository<Commande, Long> {
    void deleteByClientId(Long clientId);
    @Modifying
    @Transactional
    @Query("UPDATE Commande c SET c.vendeur = null WHERE c.vendeur.id = :vendeurId")
    void dissocierCommandesDuVendeur(@Param("vendeurId") Long vendeurId);

    // Trouver toutes les commandes d’un vendeur spécifique
    List<Commande> findByVendeurId(Long vendeurId);

    // Trouver toutes les commandes dont le vendeur est dans la liste donnée (plusieurs vendeurs)
    List<Commande> findByVendeurIdIn(List<Long> vendeurIds);

    // Tu peux aussi ajouter d'autres méthodes selon besoin, par exemple :
    // List<Commande> findByClientId(Long clientId);
}
