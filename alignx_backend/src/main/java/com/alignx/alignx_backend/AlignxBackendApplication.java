package com.alignx.alignx_backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.CrossOrigin;
import jakarta.servlet.Filter;
import jakarta.servlet.http.HttpServletResponse;
import java.util.*;

@SpringBootApplication
@RestController
@CrossOrigin(origins = "*")
public class AlignxBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(AlignxBackendApplication.class, args);
    }

    // Filter to disable caching for all HTTP responses
    @Bean
    public FilterRegistrationBean<Filter> noCacheFilter() {
        FilterRegistrationBean<Filter> registration = new FilterRegistrationBean<>();
        registration.setFilter((request, response, chain) -> {
            HttpServletResponse res = (HttpServletResponse) response;
            res.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
            res.setHeader("Pragma", "no-cache");
            res.setHeader("Expires", "0");
            chain.doFilter(request, response);
        });
        registration.addUrlPatterns("/*");
        return registration;
    }

    // Direct Test Route
    @GetMapping("/test")
    public String testRoute() {
        return "Backend is live and working!";
    }

    // System Health Check
    @GetMapping("/api/health")
    public Map<String, Object> healthCheck() {
        Map<String, Object> status = new HashMap<>();
        status.put("status", "UP");
        status.put("service", "AlignX Backend");
        status.put("timestamp", System.currentTimeMillis());
        return status;
    }

    // Posture & Pelvic Tilt Exercises Endpoint
    @GetMapping("/api/exercises/posture")
    public List<Map<String, Object>> getPostureExercises() {
        List<Map<String, Object>> exercises = new ArrayList<>();

        Map<String, Object> ex1 = new HashMap<>();
        ex1.put("id", "ex_1");
        ex1.put("title", "Hip Flexor Lunge Stretch");
        ex1.put("target", "Anterior Pelvic Tilt");
        ex1.put("duration", "45 seconds");
        ex1.put("description", "Kneel on one knee, gently push hips forward to stretch tight flexors.");
        exercises.add(ex1);

        Map<String, Object> ex2 = new HashMap<>();
        ex2.put("id", "ex_2");
        ex2.put("title", "Glute Bridges");
        ex2.put("target", "Pelvic Realignment");
        ex2.put("duration", "12 reps");
        ex2.put("description", "Lie on back, bend knees, and squeeze glutes to raise hips up.");
        exercises.add(ex2);

        Map<String, Object> ex3 = new HashMap<>();
        ex3.put("id", "ex_3");
        ex3.put("title", "Doorway Chest Stretch");
        ex3.put("target", "Rounded Shoulders");
        ex3.put("duration", "30 seconds");
        ex3.put("description", "Place forearms on door frame and lean forward gently to open up chest.");
        exercises.add(ex3);

        return exercises;
    }
}