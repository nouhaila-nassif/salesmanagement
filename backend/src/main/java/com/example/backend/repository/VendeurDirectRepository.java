package com.example.backend.repository;

import com.example.backend.entity.Superviseur;
import com.example.backend.entity.VendeurDirect;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface VendeurDirectRepository extends JpaRepository<VendeurDirect, Long> {
    List<VendeurDirect> findBySuperviseur(Superviseur superviseur);
    @Query("SELECT v FROM VendeurDirect v LEFT JOIN FETCH v.superviseur")
    List<VendeurDirect> findAllWithSuperviseur();
}

