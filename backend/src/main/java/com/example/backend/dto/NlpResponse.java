package com.example.backend.dto;


import java.util.List;

public class NlpResponse {
    private String intent;
    private List<Entity> entities;

    // getters et setters

    public static class Entity {
        private String entity;
        private String word;
        private float score;
        private int start;
        private int end;

        // getters et setters
    }

    public String getIntent() {
        return intent;
    }
    public void setIntent(String intent) {
        this.intent = intent;
    }
    public List<Entity> getEntities() {
        return entities;
    }
    public void setEntities(List<Entity> entities) {
        this.entities = entities;
    }
}
