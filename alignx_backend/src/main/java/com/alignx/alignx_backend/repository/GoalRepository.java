package com.alignx.alignx_backend.repository;

import com.alignx.alignx_backend.model.Goal;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface GoalRepository extends JpaRepository<Goal, Long> {
    List<Goal> findAllByUserIdOrderByCreatedAtDesc(String userId);
    Optional<Goal> findByIdAndUserId(Long id, String userId);
}
