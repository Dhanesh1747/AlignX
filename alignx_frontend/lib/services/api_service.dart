import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/habit_model.dart';
import '../models/exercise_model.dart';

class ApiService {
  // Use http://10.0.2.2:8080 if testing on Android Emulator, or http://localhost:8080 on Web/Desktop/iOS
  // In debug on Android emulator, 10.0.2.2 maps to host localhost.
  static String baseUrl = (defaultTargetPlatform == TargetPlatform.android && !kIsWeb)
      ? 'http://10.0.2.2:8081/api'
      : 'http://localhost:8081/api';

  // Fetch Dashboard Analytics from Spring Boot
  static Future<Map<String, dynamic>> fetchAnalytics() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/habits/analytics'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint("Backend connection error: $e");
    }
    // Fallback data if backend is offline
    return {
      "user": "Dhanesh Kumbharkar",
      "totalHabits": 5,
      "completedToday": 3,
      "currentStreak": 7,
      "postureScore": "78%",
      "dailySittingTime": "2h 34m",
      "postureAlertsCount": 2,
    };
  }

  // Fetch Posture & Pelvic Tilt Exercises
  static Future<List<Exercise>> fetchPostureExercises() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/exercises/posture'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Exercise.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint("Exercises API error: $e");
    }

    // Curated fallback exercises for Posture Alignment & Anterior Pelvic Tilt (APT)
    return [
      Exercise(
        id: "ex-1",
        title: "Kneeling Hip Flexor Stretch",
        targetArea: "Anterior Pelvic Tilt (APT) / Psoas",
        duration: "2 min (1 min/side)",
        difficulty: "Beginner",
        instructions:
            "1. Kneel on one knee, other foot flat in front.\n2. Squeeze the glute on the kneeling side and gently shift forward.\n3. Keep your torso upright and tuck your pelvis under.\n4. Hold for 30-45 seconds, then switch sides.",
        benefits:
            "Lengthens tight hip flexors caused by prolonged sitting, helping restore neutral pelvic angle.",
      ),
      Exercise(
        id: "ex-2",
        title: "Glute Bridges with Pelvic Tuck",
        targetArea: "Glutes & Hamstrings",
        duration: "3 sets x 12 reps",
        difficulty: "Beginner",
        instructions:
            "1. Lie on your back with knees bent and feet flat on the floor.\n2. Posteriorly tilt your pelvis to flatten lower back against the ground.\n3. Drive through your heels to raise hips until thighs and torso align.\n4. Squeeze glutes at top for 2 seconds, then lower slowly.",
        benefits:
            "Strengthens underactive glutes to counteract anterior pelvic tilt and support lumbar spine.",
      ),
      Exercise(
        id: "ex-3",
        title: "Chin Tucks & Neck Retraction",
        targetArea: "Cervical Spine / Forward Head Posture",
        duration: "2 min (10 reps x 5s hold)",
        difficulty: "Beginner",
        instructions:
            "1. Sit upright with shoulders back and eyes looking straight ahead.\n2. Gently draw your chin back toward your throat, making a 'double chin'.\n3. Hold for 5 seconds without tilting head up or down.\n4. Relax and repeat 10 times.",
        benefits:
            "Relieves neck strain from screen slouching and realigns the head over the shoulders.",
      ),
      Exercise(
        id: "ex-4",
        title: "Doorway Pec Stretch",
        targetArea: "Chest & Anterior Shoulders",
        duration: "2 min (30s x 2 sides)",
        difficulty: "Beginner",
        instructions:
            "1. Stand in an open doorway with forearm resting against the doorframe at 90 degrees.\n2. Gently step forward with one leg until you feel a comfortable stretch across your chest.\n3. Keep ribs down and core engaged.\n4. Hold for 30 seconds and switch sides.",
        benefits:
            "Opens tight chest muscles caused by hunching over keyboards and mobile phones.",
      ),
      Exercise(
        id: "ex-5",
        title: "Cat-Cow Spinal Mobilization",
        targetArea: "Thoracic & Lumbar Mobility",
        duration: "2 min (10 fluid cycles)",
        difficulty: "Beginner",
        instructions:
            "1. Start on all fours with wrists under shoulders and knees under hips.\n2. Inhale: Drop belly, lift chest and tailbone (Cow).\n3. Exhale: Round spine upward, tuck chin and tailbone (Cat).\n4. Move smoothly with your breath.",
        benefits:
            "Improves segmental spinal flexibility and relieves lower back stiffness.",
      ),
    ];
  }

  // Fetch User Habits from Spring Boot
  static Future<List<Habit>> fetchUserHabits(String userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/habits/user/$userId'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Habit.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint("Fetch habits error: $e");
    }

    // Default habits if backend is unreachable
    return [
      Habit(
        id: "h1",
        userId: userId,
        title: "Sit up straight & engage core",
        category: "Posture",
        currentStreak: 7,
        completedToday: true,
      ),
      Habit(
        id: "h2",
        userId: userId,
        title: "Hip Flexor Lunge Stretch",
        category: "APT Alignment",
        currentStreak: 4,
        completedToday: false,
      ),
      Habit(
        id: "h3",
        userId: userId,
        title: "Drink 3L Water",
        category: "Hydration",
        currentStreak: 12,
        completedToday: false,
      ),
      Habit(
        id: "h4",
        userId: userId,
        title: "5-Minute Standing Break",
        category: "Movement",
        currentStreak: 5,
        completedToday: true,
      ),
      Habit(
        id: "h5",
        userId: userId,
        title: "Glute Bridges (15 reps)",
        category: "APT Alignment",
        currentStreak: 3,
        completedToday: false,
      ),
    ];
  }

  // Create Habit via Spring Boot API
  static Future<bool> createHabit(Habit habit) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/habits'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(habit.toJson()),
      ).timeout(const Duration(seconds: 4));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Create habit error: $e");
      return false;
    }
  }

  // Toggle Habit completion via Spring Boot API
  static Future<bool> toggleHabitCompletion(String habitId, bool completed) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/habits/$habitId/toggle?completed=$completed'),
      ).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Toggle habit error: $e");
      return false;
    }
  }
}
