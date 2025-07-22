package com.example.backend.repository;

import com.example.backend.dto.VisiteSimpleDTO;
import com.example.backend.entity.Client;
import com.example.backend.entity.TypeClient;
import com.example.backend.entity.Visite;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface VisiteRepository extends JpaRepository<Visite, Long> {

    // Dernière visite réelle effectuée pour un client
    Optional<Visite> findTopByClientOrderByDateReelleDesc(Client client);

    // Vérifie si une visite est déjà planifiée pour un client autour d’une date
    boolean existsByClientAndDatePlanifieeBetween(Client client, LocalDate startDate, LocalDate endDate);

    // Rechercher toutes les visites pour une liste de clients
    List<Visite> findByClientIdIn(List<Long> clientIds);

    // Récupérer la dernière date planifiée pour un client
    @Query("SELECT MAX(v.datePlanifiee) FROM Visite v WHERE v.client = :client")
    LocalDate findLastDateByClient(@Param("client") Client client);

    // Dernière visite planifiée pour un client
    Optional<Visite> findTopByClientOrderByDatePlanifieeDesc(Client client);

    // ✅ Projection vers DTO enrichi (inclut adresse, téléphone et email)
    @Query("""
        SELECT new com.example.backend.dto.VisiteSimpleDTO(
            v.datePlanifiee,
            c.nom,
            coalesce(p.nomUtilisateur, 'Non attribué'),
            c.type,
            c.adresse,
            c.telephone,
            c.email
        )
        FROM Visite v
        JOIN v.client c
        LEFT JOIN v.vendeur p
        WHERE c.type IN :types
        AND v.datePlanifiee BETWEEN :dateDebut AND :dateFin
    """)
    List<VisiteSimpleDTO> findVisitesSimplesByClientTypeAndDateRange(
            @Param("types") List<TypeClient> types,
            @Param("dateDebut") LocalDate dateDebut,
            @Param("dateFin") LocalDate dateFin
    );

    // Recherche des entités Visite (pas DTO) par type client et plage de date
    @Query("SELECT v FROM Visite v WHERE v.client.type IN :types AND v.datePlanifiee BETWEEN :start AND :end")
    List<Visite> findByClientTypeInAndDatePlanifieeBetween(
            @Param("types") List<TypeClient> types,
            @Param("start") LocalDate start,
            @Param("end") LocalDate end
    );

    // Visites encore planifiées (non réalisées) pour certains types de clients
    @Query("SELECT v FROM Visite v WHERE v.client.type IN :types AND v.statut = 'PLANIFIEE'")
    List<Visite> findPendingVisitsByClientTypes(@Param("types") List<TypeClient> types);
}
