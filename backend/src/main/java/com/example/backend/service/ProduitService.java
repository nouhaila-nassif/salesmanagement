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
    @Autowired
    private NlpService nlpService;
    public double cosineSimilarity(List<Double> v1, List<Double> v2) {
        double dot = 0, normA = 0, normB = 0;
        for (int i = 0; i < v1.size(); i++) {
            dot += v1.get(i) * v2.get(i);
            normA += v1.get(i) * v1.get(i);
            normB += v2.get(i) * v2.get(i);
        }
        return dot / (Math.sqrt(normA) * Math.sqrt(normB));
    }

    public List<Produit> searchBySemanticSimilarity(String query) {
        List<Double> queryEmbedding = nlpService.getEmbedding(query);
        List<Produit> produits = produitRepository.findAll();

        return produits.stream()
                .sorted((p1, p2) -> {
                    double sim1 = cosineSimilarity(queryEmbedding, p1.getEmbeddingAsList());
                    double sim2 = cosineSimilarity(queryEmbedding, p2.getEmbeddingAsList());
                    return Double.compare(sim2, sim1);
                })
                .collect(Collectors.toList());
    }
    public List<Promotion> getPromotionsCadeauxParProduit(String nomProduit) {
        return promotionRepository.findPromoCadeauByProduitConditionNom(nomProduit);
    }
    public Produit getProduitById(Long id) {
        return produitRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Produit non trouvé"));
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
