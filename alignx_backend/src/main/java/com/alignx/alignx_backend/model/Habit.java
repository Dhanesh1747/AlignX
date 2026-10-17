package com.alignx.alignx_backend.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Habit {
    private String id;
    private String userId;
    private String title;
    private String category;
    private int currentStreak;
    private boolean completedToday;
}
