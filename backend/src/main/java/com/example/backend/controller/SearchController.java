package com.example.backend.controller;

import com.example.backend.entity.Produit;
import com.example.backend.service.ProduitService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/search-ai")
public class SearchController {
    @Autowired
    private ProduitService produitService;

    @GetMapping
    public List<Produit> search(@RequestParam String query) {
        return produitService.searchBySemanticSimilarity(query);
    }
}

