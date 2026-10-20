package com.alignx.alignx_backend.controller;

import com.alignx.alignx_backend.config.ApiAuthenticationFilter;
import com.alignx.alignx_backend.model.AppUser;
import com.alignx.alignx_backend.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class AuthController {
    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public AuthService.AuthSessionResponse register(@RequestBody RegisterRequest request) {
        return authService.register(request.name(), request.email(), request.password());
    }

    @PostMapping("/login")
    public AuthService.AuthSessionResponse login(@RequestBody LoginRequest request) {
        return authService.login(request.email(), request.password());
    }

    @GetMapping("/me")
    public Map<String, String> currentUser(HttpServletRequest request) {
        AppUser user = authenticatedUser(request);
        return Map.of("userId", user.getId(), "name", user.getName(), "email", user.getEmail());
    }

    @PostMapping("/logout")
    public Map<String, String> logout(HttpServletRequest request) {
        AppUser user = authenticatedUser(request);
        String authorization = request.getHeader("Authorization");
        authService.logout(authorization.substring(7).trim());
        return Map.of("message", "Signed out successfully.", "userId", user.getId());
    }

    private AppUser authenticatedUser(HttpServletRequest request) {
        Object user = request.getAttribute(ApiAuthenticationFilter.USER_ATTRIBUTE);
        if (user instanceof AppUser appUser) return appUser;
        throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Please sign in.");
    }

    public record RegisterRequest(String name, String email, String password) { }
    public record LoginRequest(String email, String password) { }
}
