package com.alignx.alignx_backend.service;

import com.alignx.alignx_backend.model.Goal;
import com.alignx.alignx_backend.repository.GoalRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.TemporalAdjusters;
import java.util.List;
import java.util.Locale;

@Service
public class GoalService {
    private final GoalRepository goals;

    public GoalService(GoalRepository goals) { this.goals = goals; }

    @Transactional
    public List<Goal> getGoals(String userId) {
        List<Goal> result = goals.findAllByUserIdOrderByCreatedAtDesc(userId);
        LocalDate today = LocalDate.now();
        for (Goal goal : result) {
            LocalDate currentPeriod = periodStart(goal.getType(), today);
            if (!currentPeriod.equals(goal.getPeriodStart())) {
                goal.setPeriodStart(currentPeriod);
                goal.setProgressCount(0);
            }
        }
        return goals.saveAll(result);
    }

    @Transactional
    public Goal create(String userId, Goal request) {
        if (request.getTitle() == null || request.getTitle().isBlank() || request.getTitle().trim().length() > 140)
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Goal title must be between 1 and 140 characters.");
        String type = normalized(request.getType());
        String category = normalized(request.getCategory());
        if (!type.equals("DAILY") && !type.equals("WEEKLY"))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Goal type must be DAILY or WEEKLY.");
        if (!category.equals("HEALTH") && !category.equals("PRODUCTIVITY"))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Goal category must be HEALTH or PRODUCTIVITY.");
        if (request.getTargetCount() < 1 || request.getTargetCount() > 1000)
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Target must be between 1 and 1000.");

        Goal goal = new Goal();
        goal.setUserId(userId);
        goal.setTitle(request.getTitle().trim());
        goal.setCategory(category);
        goal.setType(type);
        goal.setTargetCount(request.getTargetCount());
        goal.setProgressCount(0);
        goal.setPeriodStart(periodStart(type, LocalDate.now()));
        return goals.save(goal);
    }

    @Transactional
    public Goal increment(Long id, String userId) {
        Goal goal = goals.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Goal not found."));
        LocalDate today = LocalDate.now();
        LocalDate currentPeriod = periodStart(goal.getType(), today);
        if (!currentPeriod.equals(goal.getPeriodStart())) {
            goal.setPeriodStart(currentPeriod);
            goal.setProgressCount(0);
        }
        goal.setProgressCount(Math.min(goal.getTargetCount(), goal.getProgressCount() + 1));
        return goals.save(goal);
    }

    private static String normalized(String value) {
        return value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
    }

    private static LocalDate periodStart(String type, LocalDate date) {
        return "WEEKLY".equalsIgnoreCase(type)
                ? date.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
                : date;
    }
}
