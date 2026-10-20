package com.alignx.alignx_backend.service;

import com.alignx.alignx_backend.model.Habit;
import com.alignx.alignx_backend.repository.HabitRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class HabitService {
    private final HabitRepository habits;

    public HabitService(HabitRepository habits) {
        this.habits = habits;
    }

    @Transactional(readOnly = true)
    public List<Habit> getUserHabits(String userId) {
        return habits.findAllByUserIdOrderByCreatedAtDesc(userId);
    }

    @Transactional
    public Habit saveHabit(Habit habit, String authenticatedUserId) {
        if (habit.getTitle() == null || habit.getTitle().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Habit title is required.");
        }
        if (habit.getTitle().trim().length() > 140) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Habit title must be 140 characters or less.");
        }
        habit.setId(null);
        habit.setUserId(authenticatedUserId);
        habit.setTitle(habit.getTitle().trim());
        habit.setCategory(habit.getCategory() == null || habit.getCategory().isBlank()
                ? "General"
                : habit.getCategory().trim());
        habit.setCurrentStreak(0);
        habit.setCompletedToday(false);
        return habits.save(habit);
    }

    @Transactional
    public Habit toggleHabitCompletion(Long habitId, String userId, boolean completed) {
        Habit habit = habits.findByIdAndUserId(habitId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Habit not found."));
        if (habit.isCompletedToday() != completed) {
            habit.setCompletedToday(completed);
            habit.setCurrentStreak(Math.max(0, habit.getCurrentStreak() + (completed ? 1 : -1)));
        }
        return habits.save(habit);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getAnalytics(String userId) {
        List<Habit> userHabits = habits.findAllByUserIdOrderByCreatedAtDesc(userId);
        int total = userHabits.size();
        int completed = (int) userHabits.stream().filter(Habit::isCompletedToday).count();
        int maxStreak = userHabits.stream().mapToInt(Habit::getCurrentStreak).max().orElse(0);

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalHabits", total);
        stats.put("completedToday", completed);
        stats.put("currentStreak", maxStreak);
        stats.put("postureScore", "--");
        stats.put("dailySittingTime", "--");
        stats.put("postureAlertsCount", 0);
        return stats;
    }
}
