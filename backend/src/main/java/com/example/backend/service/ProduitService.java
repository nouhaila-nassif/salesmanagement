package com.example.backend.service;

import com.example.backend.entity.CatégorieProduit;
import com.example.backend.entity.Produit;
import com.example.backend.entity.Promotion;
import com.example.backend.repository.CatégorieProduitRepository;
import com.example.backend.repository.ProduitRepository;
import com.example.backend.repository.PromotionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class ProduitService {
    @Autowired
    private PromotionRepository promotionRepository;
    @Autowired
    private ProduitRepository produitRepository;
    @Autowired
    private CatégorieProduitRepository catégorieProduitRepository;

    public Produit createProduit(Produit produit) {
        return produitRepository.save(produit);
    }

    public List<Produit> getAllProduits() {
        return produitRepository.findAll();
    }



    public List<Promotion> getPromotionsCadeauxParProduit(String nomProduit) {
        return promotionRepository.findPromoCadeauByProduitConditionNom(nomProduit);
    }
    public Produit getProduitById(Long id) {
        return produitRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Produit non trouvé"));
    }
    public String genererContexteProduits() {
        List<Produit> produits = getAllProduits();

        if (produits.isEmpty()) {
            return "Aucun produit disponible actuellement.";
        }

        StringBuilder contexte = new StringBuilder("Voici la liste des produits disponibles :\n");
        for (Produit p : produits) {
            contexte.append("- ").append(p.getNom());
            if (p.getMarque() != null) {
                contexte.append(" (Marque : ").append(p.getMarque()).append(")");
            }
            contexte.append(", Prix : ").append(p.getPrixUnitaire()).append(" DH");
            if (p.getCategorie() != null) {
                contexte.append(", Catégorie : ").append(p.getCategorie().getNom());
            }
            List<Promotion> promos = getPromotionsCadeauxParProduit(p.getNom());
            if (!promos.isEmpty()) {
                contexte.append(", Promotions cadeaux : ");
                contexte.append(promos.stream().map(Promotion::getNom).collect(Collectors.joining(", ")));
            }
            contexte.append("\n");
        }
        return contexte.toString();
    }

    public Produit updateProduit(Long id, Produit newData) {
        Produit existing = getProduitById(id); // méthode qui lance une exception si absent

        existing.setNom(newData.getNom());
        existing.setDescription(newData.getDescription());
        existing.setMarque(newData.getMarque());
        existing.setPrixUnitaire(newData.getPrixUnitaire());
        existing.setImageUrl(newData.getImageUrl());
        existing.setImageBase64(newData.getImageBase64());

        if (newData.getCategorie() != null && newData.getCategorie().getId() != null) {
            Optional<CatégorieProduit> categorieOpt = catégorieProduitRepository.findById(newData.getCategorie().getId());
            categorieOpt.ifPresent(existing::setCategorie);
        }

        // Gérer promotions etc. ici si besoin

        return produitRepository.save(existing);
    }

    public void deleteProduit(Long id) {
        produitRepository.deleteById(id);
    }
}
