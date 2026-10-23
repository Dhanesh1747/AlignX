package com.alignx.alignx_backend.service;

import com.alignx.alignx_backend.model.Goal;
import com.alignx.alignx_backend.repository.GoalRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.TemporalAdjusters;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GoalServiceTest {
    @Mock
    private GoalRepository goals;

    private GoalService service;

    @BeforeEach
    void setUp() {
        service = new GoalService(goals);
    }

    @Test
    void createTrimsAndNormalizesInputAndUsesAuthenticatedOwner() {
        Goal request = goal("  Stretch  ", "health", "weekly", 4, 0, LocalDate.now());
        when(goals.save(any(Goal.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Goal saved = service.create("signed-in-user", request);

        assertEquals("signed-in-user", saved.getUserId());
        assertEquals("Stretch", saved.getTitle());
        assertEquals("HEALTH", saved.getCategory());
        assertEquals("WEEKLY", saved.getType());
        assertEquals(4, saved.getTargetCount());
        assertEquals(0, saved.getProgressCount());
        assertEquals(LocalDate.now().with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)), saved.getPeriodStart());
    }

    @Test
    void createRejectsZeroTarget() {
        Goal request = goal("Stretch", "HEALTH", "DAILY", 0, 0, LocalDate.now());

        assertThrows(ResponseStatusException.class, () -> service.create("user-1", request));
    }

    @Test
    void getGoalsResetsProgressWhenDailyPeriodChanges() {
        Goal daily = goal("Walk", "HEALTH", "DAILY", 2, 2, LocalDate.now().minusDays(1));
        when(goals.findAllByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of(daily));
        when(goals.saveAll(anyList())).thenAnswer(invocation -> invocation.getArgument(0));

        List<Goal> result = service.getGoals("user-1");

        assertEquals(0, result.get(0).getProgressCount());
        assertEquals(LocalDate.now(), result.get(0).getPeriodStart());
        verify(goals).saveAll(anyList());
    }

    @Test
    void getGoalsResetsWeeklyProgressAtTheNextWeek() {
        LocalDate lastWeek = LocalDate.now().with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)).minusWeeks(1);
        Goal weekly = goal("Exercise", "HEALTH", "WEEKLY", 3, 2, lastWeek);
        when(goals.findAllByUserIdOrderByCreatedAtDesc("user-1")).thenReturn(List.of(weekly));
        when(goals.saveAll(anyList())).thenAnswer(invocation -> invocation.getArgument(0));

        List<Goal> result = service.getGoals("user-1");

        assertEquals(0, result.get(0).getProgressCount());
        assertEquals(LocalDate.now().with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)), result.get(0).getPeriodStart());
    }

    @Test
    void incrementDoesNotExceedGoalTarget() {
        Goal complete = goal("Read", "PRODUCTIVITY", "DAILY", 1, 1, LocalDate.now());
        when(goals.findByIdAndUserId(9L, "user-1")).thenReturn(Optional.of(complete));
        when(goals.save(complete)).thenReturn(complete);

        Goal result = service.increment(9L, "user-1");

        assertEquals(1, result.getProgressCount());
    }

    @Test
    void incrementCannotAccessAnotherUsersGoal() {
        when(goals.findByIdAndUserId(7L, "user-1")).thenReturn(Optional.empty());

        assertThrows(ResponseStatusException.class, () -> service.increment(7L, "user-1"));
        verify(goals).findByIdAndUserId(7L, "user-1");
    }

    private static Goal goal(String title, String category, String type, int target, int progress, LocalDate periodStart) {
        Goal goal = new Goal();
        goal.setTitle(title);
        goal.setCategory(category);
        goal.setType(type);
        goal.setTargetCount(target);
        goal.setProgressCount(progress);
        goal.setPeriodStart(periodStart);
        return goal;
    }
}
