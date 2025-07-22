package com.example.backend.service;

import com.example.backend.dto.NlpResponse;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;
@Service
public class NlpService {
    private final RestTemplate restTemplate = new RestTemplate();

    public List<Double> getEmbedding(String text) {
        String url = "http://127.0.0.1:8000/embedding";
        Map<String, String> request = Map.of("text", text);
        ResponseEntity<Map> response = restTemplate.postForEntity(url, request, Map.class);
        return (List<Double>) response.getBody().get("embedding");
    }
    public double cosineSimilarity(List<Double> v1, List<Double> v2) {
        double dot = 0, normA = 0, normB = 0;
        for (int i = 0; i < v1.size(); i++) {
            dot += v1.get(i) * v2.get(i);
            normA += v1.get(i) * v1.get(i);
            normB += v2.get(i) * v2.get(i);
        }
        return dot / (Math.sqrt(normA) * Math.sqrt(normB));
    }

}


