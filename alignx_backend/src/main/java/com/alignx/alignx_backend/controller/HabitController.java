package com.alignx.alignx_backend.controller;

import com.alignx.alignx_backend.config.ApiAuthenticationFilter;
import com.alignx.alignx_backend.model.AppUser;
import com.alignx.alignx_backend.model.Habit;
import com.alignx.alignx_backend.service.HabitService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/habits")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class HabitController {
    private final HabitService habitService;

    public HabitController(HabitService habitService) {
        this.habitService = habitService;
    }

    @GetMapping("/analytics")
    public Map<String, Object> getHabitAnalytics(HttpServletRequest request) {
        return habitService.getAnalytics(currentUser(request).getId());
    }

    @GetMapping({"/user/{userId}", "/db/{userId}"})
    public List<Habit> getHabitsByUser(@PathVariable String userId, HttpServletRequest request) {
        AppUser user = currentUser(request);
        if (!user.getId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You can only access your own habits.");
        }
        return habitService.getUserHabits(user.getId());
    }

    @PostMapping
    public Habit createHabit(@RequestBody Habit habit, HttpServletRequest request) {
        return habitService.saveHabit(habit, currentUser(request).getId());
    }

    @PostMapping("/db")
    public Habit createHabitInDb(
            @RequestParam(required = false) String title,
            @RequestParam(required = false) String category,
            @RequestBody(required = false) Habit habitBody,
            HttpServletRequest request) {
        Habit habit = habitBody == null ? new Habit() : habitBody;
        if (title != null && !title.isBlank()) habit.setTitle(title);
        if (category != null && !category.isBlank()) habit.setCategory(category);
        return habitService.saveHabit(habit, currentUser(request).getId());
    }

    @PutMapping("/{id}/toggle")
    public Habit toggleHabit(
            @PathVariable Long id,
            @RequestParam boolean completed,
            HttpServletRequest request) {
        return habitService.toggleHabitCompletion(id, currentUser(request).getId(), completed);
    }

    private AppUser currentUser(HttpServletRequest request) {
        Object user = request.getAttribute(ApiAuthenticationFilter.USER_ATTRIBUTE);
        if (user instanceof AppUser appUser) return appUser;
        throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Please sign in.");
    }
}
