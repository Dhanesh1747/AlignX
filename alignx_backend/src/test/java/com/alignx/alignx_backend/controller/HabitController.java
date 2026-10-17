package com.alignx.alignx_backend.controller;

import com.alignx.alignx_backend.model.Habit;
import com.alignx.alignx_backend.service.HabitService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/habits")
@CrossOrigin(origins = "*")
public class HabitController {

    @Autowired
    private HabitService habitService;

    // GET: Analytics Overview Endpoint
    @GetMapping("/analytics")
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

    // GET: User Habits List from Firestore
    @GetMapping("/user/{userId}")
    public List<Habit> getHabitsByUser(@PathVariable String userId) {
        try {
            return habitService.getUserHabits(userId);
        } catch (ExecutionException | InterruptedException e) {
            return Collections.emptyList();
        }
    }

    // POST: Create New Habit
    @PostMapping
    public String createHabit(@RequestBody Habit habit) {
        try {
            return habitService.saveHabit(habit);
        } catch (ExecutionException | InterruptedException e) {
            return "Error creating habit: " + e.getMessage();
        }
    }

    // PUT: Toggle Habit Status
    @PutMapping("/{id}/toggle")
    public String toggleHabit(@PathVariable String id, @RequestParam boolean completed) {
        try {
            return habitService.toggleHabitCompletion(id, completed);
        } catch (ExecutionException | InterruptedException e) {
            return "Error updating habit: " + e.getMessage();
        }
    }
}