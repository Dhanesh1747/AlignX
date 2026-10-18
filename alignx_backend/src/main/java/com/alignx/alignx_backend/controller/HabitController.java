package com.alignx.alignx_backend.controller;

import com.alignx.alignx_backend.model.Habit;
import com.alignx.alignx_backend.service.HabitService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.concurrent.ExecutionException;

@RestController
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class HabitController {

    @Autowired
    private HabitService habitService;

    // Health Check Route
    @GetMapping({"/test", "/api/test"})
    public String testRoute() {
        return "Backend is live and connected!";
    }

    // Analytics Route
    @GetMapping("/api/habits/analytics")
    public Map<String, Object> getHabitAnalytics() {
        return habitService.getAnalytics("user-dhanesh");
    }

    // Fetch User Habits (Supports both /user/{userId} and /db/{userId})
    @GetMapping({"/api/habits/user/{userId}", "/api/habits/db/{userId}"})
    public List<Habit> getHabitsByUser(@PathVariable String userId) {
        try {
            return habitService.getUserHabits(userId);
        } catch (ExecutionException | InterruptedException e) {
            return Collections.emptyList();
        }
    }

    // Create Habit via JSON body (Matches Flutter ApiService.createHabit)
    @PostMapping("/api/habits")
    public Map<String, String> createHabit(@RequestBody Habit habit) {
        Map<String, String> res = new HashMap<>();
        try {
            String docId = habitService.saveHabit(habit);
            res.put("status", "success");
            res.put("documentId", docId);
        } catch (ExecutionException | InterruptedException e) {
            res.put("status", "error");
            res.put("message", e.getMessage());
        }
        return res;
    }

    // Create Habit via Query Params / Request body (Backward-compatible /api/habits/db)
    @PostMapping("/api/habits/db")
    public Map<String, String> createHabitInDb(
            @RequestParam(required = false) String userId,
            @RequestParam(required = false) String title,
            @RequestParam(required = false) String category,
            @RequestBody(required = false) Habit habitBody) {
        Map<String, String> res = new HashMap<>();
        try {
            Habit habit = habitBody != null ? habitBody : new Habit();
            if (userId != null && !userId.isEmpty()) habit.setUserId(userId);
            if (title != null && !title.isEmpty()) habit.setTitle(title);
            if (category != null && !category.isEmpty()) habit.setCategory(category);
            String docId = habitService.saveHabit(habit);
            res.put("status", "success");
            res.put("documentId", docId);
        } catch (ExecutionException | InterruptedException e) {
            res.put("status", "error");
            res.put("message", e.getMessage());
        }
        return res;
    }

    // Toggle Habit Status (Matches Flutter ApiService.toggleHabitCompletion)
    @PutMapping("/api/habits/{id}/toggle")
    public Map<String, Object> toggleHabit(@PathVariable String id, @RequestParam boolean completed) {
        Map<String, Object> res = new HashMap<>();
        try {
            String result = habitService.toggleHabitCompletion(id, completed);
            res.put("status", "success");
            res.put("result", result);
        } catch (ExecutionException | InterruptedException e) {
            res.put("status", "error");
            res.put("message", e.getMessage());
        }
        return res;
    }
}
