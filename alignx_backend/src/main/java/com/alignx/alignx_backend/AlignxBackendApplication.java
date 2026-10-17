package com.alignx.alignx_backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.CrossOrigin;
import java.util.HashMap;
import java.util.Map;

@SpringBootApplication
@RestController
@CrossOrigin(origins = "*")
public class AlignxBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(AlignxBackendApplication.class, args);
    }

    // Direct Test Route
    @GetMapping("/test")
    public String testRoute() {
        return "Backend is live and working!";
    }

    // Direct Analytics Endpoint
    @GetMapping("/api/habits/analytics")
    public Map<String, Object> getHabitAnalytics() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("user", "Dhanesh Kumbharkar");
        stats.put("totalHabits", 5);
        stats.put("completedToday", 3);
        stats.put("currentStreak", 7);
        stats.put("postureScore", "78%");
        stats.put("dailySittingTime", "2h 34m");
        stats.put("postureAlertsCount", 2);
        return stats;
    }
}