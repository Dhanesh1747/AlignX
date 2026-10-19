package com.alignx.alignx_backend.controller;

import com.alignx.alignx_backend.model.User;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    // Thread-safe user storage with demo accounts pre-seeded
    private final Map<String, User> userDatabase = new ConcurrentHashMap<>();

    public AuthController() {
        // Pre-seed default user
        User defaultUser = new User(
            "user-dhanesh",
            "Dhanesh Kumbharkar",
            "dhanesh@alignx.com",
            "password123"
        );
        userDatabase.put(defaultUser.getEmail().toLowerCase(), defaultUser);

        User demoUser = new User(
            "user-demo",
            "AlignX Explorer",
            "demo@alignx.com",
            "alignx2026"
        );
        userDatabase.put(demoUser.getEmail().toLowerCase(), demoUser);
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        String email = credentials.get("email");
        String password = credentials.get("password");

        if (email == null || email.trim().isEmpty() || password == null || password.trim().isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("success", false, "message", "Email and password are required."));
        }

        String normalizedEmail = email.trim().toLowerCase();
        User user = userDatabase.get(normalizedEmail);

        if (user != null && user.getPassword().equals(password)) {
            String token = "alignx_jwt_" + UUID.randomUUID().toString().replace("-", "");
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Login successful!");
            response.put("token", token);
            response.put("user", Map.of(
                "id", user.getId(),
                "name", user.getName(),
                "email", user.getEmail()
            ));
            return ResponseEntity.ok(response);
        }

        // Allow graceful sign-in for demo convenience if user provided valid credentials
        if (user == null && password.length() >= 6) {
            String generatedId = "user_" + UUID.randomUUID().toString().substring(0, 8);
            String name = email.split("@")[0];
            if (name.length() > 0) {
                name = Character.toUpperCase(name.charAt(0)) + name.substring(1);
            }
            User newUser = new User(generatedId, name, normalizedEmail, password);
            userDatabase.put(normalizedEmail, newUser);

            String token = "alignx_jwt_" + UUID.randomUUID().toString().replace("-", "");
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Welcome to AlignX!");
            response.put("token", token);
            response.put("user", Map.of(
                "id", newUser.getId(),
                "name", newUser.getName(),
                "email", newUser.getEmail()
            ));
            return ResponseEntity.ok(response);
        }

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .body(Map.of("success", false, "message", "Invalid email or password."));
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody Map<String, String> request) {
        String name = request.get("name");
        String email = request.get("email");
        String password = request.get("password");

        if (email == null || email.trim().isEmpty() || password == null || password.trim().isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("success", false, "message", "Name, email, and password are required."));
        }

        String normalizedEmail = email.trim().toLowerCase();
        if (userDatabase.containsKey(normalizedEmail)) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(Map.of("success", false, "message", "An account with this email already exists."));
        }

        String displayName = (name != null && !name.trim().isEmpty()) ? name.trim() : email.split("@")[0];
        String id = "user_" + UUID.randomUUID().toString().substring(0, 8);
        User newUser = new User(id, displayName, normalizedEmail, password);
        userDatabase.put(normalizedEmail, newUser);

        String token = "alignx_jwt_" + UUID.randomUUID().toString().replace("-", "");
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Account registered successfully!");
        response.put("token", token);
        response.put("user", Map.of(
            "id", newUser.getId(),
            "name", newUser.getName(),
            "email", newUser.getEmail()
        ));
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Logged out successfully.");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(@RequestParam(value = "email", required = false) String email) {
        if (email != null && userDatabase.containsKey(email.toLowerCase())) {
            User user = userDatabase.get(email.toLowerCase());
            return ResponseEntity.ok(Map.of(
                "id", user.getId(),
                "name", user.getName(),
                "email", user.getEmail()
            ));
        }
        return ResponseEntity.ok(Map.of(
            "id", "user-dhanesh",
            "name", "Dhanesh Kumbharkar",
            "email", "dhanesh@alignx.com"
        ));
    }
}
