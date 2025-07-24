package com.example.backend.repository;

import com.example.backend.entity.Client;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ClientRepository extends JpaRepository<Client, Long> {

    // Trouver clients liés à une liste d'IDs de routes
    List<Client> findByRoutesIdIn(List<Long> routeIds);
    // ✅ Recherche d'un client par son nom exact
    Optional<Client> findByNom(String nom);
    // Trouver clients par vendeur via relation ManyToMany entre Route et Vendeur (Utilisateur)
    @Query("SELECT DISTINCT c FROM Client c JOIN c.routes r JOIN r.vendeurs v WHERE v.id = :vendeurId")
    List<Client> findClientsByVendeurId(@Param("vendeurId") Long vendeurId);
    @Query("SELECT c FROM Client c WHERE LOWER(TRIM(c.nom)) = LOWER(TRIM(:nom))")
    Optional<Client> findByNomIgnoreCaseAndTrimmed(@Param("nom") String nom);

    // Récupérer tous les clients avec leurs routes (fetch join)
    @Query("SELECT DISTINCT c FROM Client c LEFT JOIN FETCH c.routes")
    List<Client> findAllWithDetails();

    // Optionnel : utiliser EntityGraph (alternative)
    // @EntityGraph(attributePaths = {"routes"})
    // List<Client> findAll();
}
