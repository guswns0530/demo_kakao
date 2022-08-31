package com.oauth2.sample.web.security.dto;

import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class User {
    private Long id;
    private String name;
    private String email;
    private String imageUrl;
    private Role role;
    private Boolean emailVerified = false;
    @JsonIgnore
    private String password;
    private AuthProvider provider;
    private String providerId;

    public User update(String name, String imageUrl) {
        this.name = name;
        this.imageUrl = imageUrl;

        return this;
    }
}
