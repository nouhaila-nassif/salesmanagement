package com.example.backend.dto;
public class CreatePreVendeurRequest {
    private String newPreVendeurUsername;
    private String newPreVendeurPassword;
    private String telephone;
    private String email;

    // getters et setters
    public String getNewPreVendeurUsername() { return newPreVendeurUsername; }
    public void setNewPreVendeurUsername(String newPreVendeurUsername) { this.newPreVendeurUsername = newPreVendeurUsername; }

    public String getNewPreVendeurPassword() { return newPreVendeurPassword; }
    public void setNewPreVendeurPassword(String newPreVendeurPassword) { this.newPreVendeurPassword = newPreVendeurPassword; }

    public String getTelephone() { return telephone; }
    public void setTelephone(String telephone) { this.telephone = telephone; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
}
