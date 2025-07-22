package com.example.backend.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateVendeurDirectRequest {
    private String newVendeurDirectUsername;
    private String newVendeurDirectPassword;
    private Long superviseurId; // ✅ Ajout ici

    public Long getSuperviseurId() {
        return superviseurId;
    }

    public void setSuperviseurId(Long superviseurId) {
        this.superviseurId = superviseurId;
    }

    public String getNewVendeurDirectUsername() {
        return newVendeurDirectUsername;
    }

    public void setNewVendeurDirectUsername(String newVendeurDirectUsername) {
        this.newVendeurDirectUsername = newVendeurDirectUsername;
    }

    public String getNewVendeurDirectPassword() {
        return newVendeurDirectPassword;
    }

    public void setNewVendeurDirectPassword(String newVendeurDirectPassword) {
        this.newVendeurDirectPassword = newVendeurDirectPassword;
    }
}
