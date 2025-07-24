package com.example.backend.service;
import com.example.backend.dto.RouteDTO;
import com.example.backend.entity.Client;
import com.example.backend.entity.Route;
import com.example.backend.entity.Utilisateur;
import com.example.backend.entity.Vendeur;
import com.example.backend.repository.ClientRepository;
import com.example.backend.repository.RouteRepository;
import com.example.backend.repository.UtilisateurRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;

@Service
public class DislogroupInfoService {

    private final RestTemplate restTemplate;
    private final GeminiService geminiService;

    public DislogroupInfoService(GeminiService geminiService) {
        this.restTemplate = new RestTemplate();
        this.geminiService = geminiService;
    }

    public String getDislogroupContent() {
        StringBuilder contenuGlobal = new StringBuilder();

        // Page d'accueil
        contenuGlobal.append(extraireTexte(
                restTemplate.getForObject("https://dislogroup.com/", String.class)
        ));

        // Page Contact
        try {
            contenuGlobal.append("\n").append(extraireTexte(
                    restTemplate.getForObject("https://dislogroup.com/fr/contact/", String.class)
            ));
        } catch (Exception e) {
            System.err.println("Impossible de récupérer la page Contact: " + e.getMessage());
        }

        return contenuGlobal.toString();
    }


    private String extraireTexte(String html) {
        Document doc = Jsoup.parse(html);

        StringBuilder sb = new StringBuilder();

        // Récupérer tout le contenu textuel pertinent
        doc.select("h1, h2, h3, p, address, footer").forEach(element -> {
            sb.append(element.text()).append("\n");
        });

        return sb.toString();
    }


    public String repondreQuestionSurDislogroup(String question) {
        String contenu = getDislogroupContent();
        // Envoi la question + contenu comme contexte à Gemini
        return geminiService.askGemini(question, contenu);
    }
}
