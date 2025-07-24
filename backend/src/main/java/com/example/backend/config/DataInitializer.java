package com.example.backend.config;

import com.example.backend.entity.CatégorieProduit;
import com.example.backend.repository.CatégorieProduitRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class DataInitializer implements CommandLineRunner {

    private final CatégorieProduitRepository catégorieProduitRepository;

    public DataInitializer(CatégorieProduitRepository catégorieProduitRepository) {
        this.catégorieProduitRepository = catégorieProduitRepository;
    }

    @Override
    public void run(String... args) {

        insertIfNotExists("Boissons", "Toutes les boissons disponibles");
        insertIfNotExists("Produits frais", "Fruits, légumes, produits laitiers...");
        insertIfNotExists("Produits alimentaires", "Épicerie, conserves, produits secs...");
        insertIfNotExists("Hygiène et soins", "Soins du corps, savons, shampoings...");
        insertIfNotExists("Snacks", "Produits à grignoter");

    }

    private void insertIfNotExists(String nom, String description) {
        if (catégorieProduitRepository.findByNom(nom).isEmpty()) {
            CatégorieProduit cat = new CatégorieProduit();
            cat.setNom(nom);
            cat.setDescription(description);
            catégorieProduitRepository.save(cat);
        } else {
        }
    }


}
