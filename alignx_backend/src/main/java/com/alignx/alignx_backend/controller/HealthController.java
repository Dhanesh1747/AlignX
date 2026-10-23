package com.alignx.alignx_backend.controller;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class HealthController {
    @GetMapping({"/test", "/api/test"})
    public Map<String, String> health() {
        return Map.of("status", "UP", "message", "Backend is live");
    }
}
