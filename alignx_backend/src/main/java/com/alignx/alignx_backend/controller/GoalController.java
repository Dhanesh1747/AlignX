package com.alignx.alignx_backend.controller;

import com.alignx.alignx_backend.config.ApiAuthenticationFilter;
import com.alignx.alignx_backend.model.AppUser;
import com.alignx.alignx_backend.model.Goal;
import com.alignx.alignx_backend.service.GoalService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import java.util.List;

@RestController
@RequestMapping("/api/goals")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class GoalController {
    private final GoalService goalService;

    public GoalController(GoalService goalService) { this.goalService = goalService; }

    @GetMapping
    public List<Goal> getGoals(HttpServletRequest request) {
        return goalService.getGoals(currentUser(request).getId());
    }

    @PostMapping
    public Goal createGoal(@RequestBody Goal goal, HttpServletRequest request) {
        return goalService.create(currentUser(request).getId(), goal);
    }

    @PostMapping("/{id}/progress")
    public Goal incrementProgress(@PathVariable Long id, HttpServletRequest request) {
        return goalService.increment(id, currentUser(request).getId());
    }

    private AppUser currentUser(HttpServletRequest request) {
        Object user = request.getAttribute(ApiAuthenticationFilter.USER_ATTRIBUTE);
        if (user instanceof AppUser appUser) return appUser;
        throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Please sign in.");
    }
}
