package com.example.backend.service;

import com.example.backend.entity.CatégorieProduit;
import com.example.backend.repository.CatégorieProduitRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CatégorieProduitService {

    @Autowired
    private CatégorieProduitRepository catégorieProduitRepository;

    public CatégorieProduit create(CatégorieProduit categorie) {
        return catégorieProduitRepository.save(categorie);
    }

    public List<CatégorieProduit> getAll() {
        return catégorieProduitRepository.findAll();
    }

    public CatégorieProduit getById(Long id) {
        return catégorieProduitRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Catégorie non trouvée"));
    }

    public CatégorieProduit update(Long id, CatégorieProduit newData) {
        CatégorieProduit existing = getById(id);
        existing.setNom(newData.getNom());
        return catégorieProduitRepository.save(existing);
    }

    public void delete(Long id) {
        catégorieProduitRepository.deleteById(id);
    }
}
