package com.example.backend.repository;

import com.example.backend.entity.Superviseur;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SuperviseurRepository extends JpaRepository<Superviseur, Long> {

}
