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

    // Les 2 dernières visites d'un client (triées par date planifiée décroissante)
    List<Visite> findTop2ByClientIdOrderByDatePlanifieeDesc(Long clientId);

    // Vérifie s'il existe une visite autour d’une date donnée
    boolean existsByClientAndDatePlanifieeBetween(Client client, LocalDate startDate, LocalDate endDate);

    // Toutes les visites pour une liste d'IDs clients
    List<Visite> findByClientIdIn(List<Long> clientIds);

    // Dernière date planifiée d’un client
    @Query("SELECT MAX(v.datePlanifiee) FROM Visite v WHERE v.client = :client")
    LocalDate findLastDateByClient(@Param("client") Client client);

    // Dernière visite planifiée (pas nécessairement réalisée)
    Optional<Visite> findTopByClientOrderByDatePlanifieeDesc(Client client);

    // Projection vers DTO avec données client enrichies
    @Query("""
        SELECT new com.example.backend.dto.VisiteSimpleDTO(
        v.id,
            v.datePlanifiee,
            c.nom,
            COALESCE(p.nomUtilisateur, 'Non attribué'),
            c.type,
            c.adresse,
            c.telephone,
 
            c.email,
            v.statut
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

    // Toutes les entités Visite (pas les DTO) par type client et date planifiée
    @Query("""
        SELECT v FROM Visite v
        WHERE v.client.type IN :types
          AND v.datePlanifiee BETWEEN :start AND :end
    """)
    List<Visite> findByClientTypeInAndDatePlanifieeBetween(
            @Param("types") List<TypeClient> types,
            @Param("start") LocalDate start,
            @Param("end") LocalDate end
    );

    // Visites encore planifiées (non réalisées)
    @Query("""
        SELECT v FROM Visite v
        WHERE v.client.type IN :types
          AND v.statut = 'PLANIFIEE'
    """)
    List<Visite> findPendingVisitsByClientTypes(@Param("types") List<TypeClient> types);
}
