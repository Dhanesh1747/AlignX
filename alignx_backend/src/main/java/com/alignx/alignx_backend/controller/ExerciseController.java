package com.alignx.alignx_backend.controller;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.*;

@RestController
@RequestMapping("/api/exercises")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class ExerciseController {

    @GetMapping("/posture")
    public List<Map<String, Object>> getPostureExercises() {
        List<Map<String, Object>> exercises = new ArrayList<>();

        Map<String, Object> ex1 = new HashMap<>();
        ex1.put("id", "ex-1");
        ex1.put("title", "Kneeling Hip Flexor Stretch");
        ex1.put("targetArea", "Anterior Pelvic Tilt (APT) / Psoas");
        ex1.put("target", "Anterior Pelvic Tilt");
        ex1.put("duration", "2 min (1 min/side)");
        ex1.put("difficulty", "Beginner");
        ex1.put("instructions", "1. Kneel on one knee, other foot flat in front.\n2. Squeeze the glute on the kneeling side and gently shift forward.\n3. Keep your torso upright and tuck your pelvis under.\n4. Hold for 30-45 seconds, then switch sides.");
        ex1.put("description", "Kneel on one knee, gently push hips forward to stretch tight flexors.");
        ex1.put("benefits", "Lengthens tight hip flexors caused by prolonged sitting, helping restore neutral pelvic angle.");
        exercises.add(ex1);

        Map<String, Object> ex2 = new HashMap<>();
        ex2.put("id", "ex-2");
        ex2.put("title", "Glute Bridges with Pelvic Tuck");
        ex2.put("targetArea", "Glutes & Hamstrings");
        ex2.put("target", "Pelvic Realignment");
        ex2.put("duration", "3 sets x 12 reps");
        ex2.put("difficulty", "Beginner");
        ex2.put("instructions", "1. Lie on your back with knees bent and feet flat on the floor.\n2. Posteriorly tilt your pelvis to flatten lower back against the ground.\n3. Drive through your heels to raise hips until thighs and torso align.\n4. Squeeze glutes at top for 2 seconds, then lower slowly.");
        ex2.put("description", "Lie on back, bend knees, and squeeze glutes to raise hips up.");
        ex2.put("benefits", "Strengthens underactive glutes to counteract anterior pelvic tilt and support lumbar spine.");
        exercises.add(ex2);

        Map<String, Object> ex3 = new HashMap<>();
        ex3.put("id", "ex-3");
        ex3.put("title", "Chin Tucks & Neck Retraction");
        ex3.put("targetArea", "Cervical Spine / Forward Head Posture");
        ex3.put("target", "Forward Head Posture");
        ex3.put("duration", "2 min (10 reps x 5s hold)");
        ex3.put("difficulty", "Beginner");
        ex3.put("instructions", "1. Sit upright with shoulders back and eyes looking straight ahead.\n2. Gently draw your chin back toward your throat, making a 'double chin'.\n3. Hold for 5 seconds without tilting head up or down.\n4. Relax and repeat 10 times.");
        ex3.put("description", "Gently draw your chin back toward your throat to relieve neck strain.");
        ex3.put("benefits", "Relieves neck strain from screen slouching and realigns the head over the shoulders.");
        exercises.add(ex3);

        Map<String, Object> ex4 = new HashMap<>();
        ex4.put("id", "ex-4");
        ex4.put("title", "Doorway Pec Stretch");
        ex4.put("targetArea", "Chest & Anterior Shoulders");
        ex4.put("target", "Rounded Shoulders");
        ex4.put("duration", "2 min (30s x 2 sides)");
        ex4.put("difficulty", "Beginner");
        ex4.put("instructions", "1. Stand in an open doorway with forearm resting against the doorframe at 90 degrees.\n2. Gently step forward with one leg until you feel a comfortable stretch across your chest.\n3. Keep ribs down and core engaged.\n4. Hold for 30 seconds and switch sides.");
        ex4.put("description", "Place forearms on door frame and lean forward gently to open up chest.");
        ex4.put("benefits", "Opens tight chest muscles caused by hunching over keyboards and mobile phones.");
        exercises.add(ex4);

        Map<String, Object> ex5 = new HashMap<>();
        ex5.put("id", "ex-5");
        ex5.put("title", "Cat-Cow Spinal Mobilization");
        ex5.put("targetArea", "Thoracic & Lumbar Mobility");
        ex5.put("target", "Spine Decompression");
        ex5.put("duration", "2 min (10 fluid cycles)");
        ex5.put("difficulty", "Beginner");
        ex5.put("instructions", "1. Start on all fours with wrists under shoulders and knees under hips.\n2. Inhale: Drop belly, lift chest and tailbone (Cow).\n3. Exhale: Round spine upward, tuck chin and tailbone (Cat).\n4. Move smoothly with your breath.");
        ex5.put("description", "Alternate between arching and rounding back to increase spinal flexibility.");
        ex5.put("benefits", "Improves segmental spinal flexibility and relieves lower back stiffness.");
        exercises.add(ex5);

        return exercises;
    }
}
