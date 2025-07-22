package com.example.backend.dto;

import lombok.Getter;

@Getter
public class AuthResponse {
    // ✅ Getter et setter
    private String token;

    // ✅ Constructeur sans argument (optionnel mais utile)
    public AuthResponse() {
    }

    // ✅ Constructeur avec token
    public AuthResponse(String token) {
        this.token = token;
    }

    public void setToken(String token) {
        this.token = token;
    }
}
