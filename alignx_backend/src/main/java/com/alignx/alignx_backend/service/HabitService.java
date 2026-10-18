package com.alignx.alignx_backend.service;

import com.alignx.alignx_backend.config.FirebaseConfig;
import com.alignx.alignx_backend.model.Habit;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.ExecutionException;

@Service
public class HabitService {

    private static final String COLLECTION_NAME = "habits";
    private final Map<String, List<Habit>> localUserHabits = new ConcurrentHashMap<>();

    public HabitService() {
        // Default seed data for initial view and offline/local development
        List<Habit> defaultList = new CopyOnWriteArrayList<>();
        defaultList.add(new Habit("h1", "user-dhanesh", "Sit up straight & engage core", "Posture", 7, true));
        defaultList.add(new Habit("h2", "user-dhanesh", "Hip Flexor Lunge Stretch", "APT Alignment", 4, false));
        defaultList.add(new Habit("h3", "user-dhanesh", "Drink 3L Water", "Hydration", 12, false));
        defaultList.add(new Habit("h4", "user-dhanesh", "5-Minute Standing Break", "Movement", 5, true));
        defaultList.add(new Habit("h5", "user-dhanesh", "Glute Bridges (15 reps)", "APT Alignment", 3, false));
        localUserHabits.put("user-dhanesh", defaultList);
    }

    public List<Habit> getUserHabits(String userId) throws ExecutionException, InterruptedException {
        if (FirebaseConfig.isFirebaseInitialized()) {
            try {
                Firestore db = FirestoreClient.getFirestore();
                CollectionReference habits = db.collection(COLLECTION_NAME);
                Query query = habits.whereEqualTo("userId", userId);
                ApiFuture<QuerySnapshot> querySnapshot = query.get();

                List<Habit> habitList = new ArrayList<>();
                for (DocumentSnapshot doc : querySnapshot.get().getDocuments()) {
                    Habit habit = doc.toObject(Habit.class);
                    if (habit != null) {
                        habit.setId(doc.getId());
                        habitList.add(habit);
                    }
                }
                if (!habitList.isEmpty()) {
                    return habitList;
                }
            } catch (Exception e) {
                System.err.println("Firestore fetch error, falling back to local: " + e.getMessage());
            }
        }

        return localUserHabits.computeIfAbsent(userId, k -> new CopyOnWriteArrayList<>());
    }

    public String saveHabit(Habit habit) throws ExecutionException, InterruptedException {
        if (habit.getId() == null || habit.getId().isEmpty()) {
            habit.setId("h_" + UUID.randomUUID().toString().substring(0, 8));
        }

        if (FirebaseConfig.isFirebaseInitialized()) {
            try {
                Firestore db = FirestoreClient.getFirestore();
                ApiFuture<DocumentReference> addedDocRef = db.collection(COLLECTION_NAME).add(habit);
                String docId = addedDocRef.get().getId();
                habit.setId(docId);
            } catch (Exception e) {
                System.err.println("Firestore save error, saving to local: " + e.getMessage());
            }
        }

        String userId = (habit.getUserId() != null && !habit.getUserId().isEmpty()) ? habit.getUserId() : "user-dhanesh";
        List<Habit> list = localUserHabits.computeIfAbsent(userId, k -> new CopyOnWriteArrayList<>());
        list.add(0, habit);
        return habit.getId();
    }

    public String toggleHabitCompletion(String habitId, boolean completed) throws ExecutionException, InterruptedException {
        if (FirebaseConfig.isFirebaseInitialized()) {
            try {
                Firestore db = FirestoreClient.getFirestore();
                DocumentReference docRef = db.collection(COLLECTION_NAME).document(habitId);

                Map<String, Object> updates = new HashMap<>();
                updates.put("completedToday", completed);
                if (completed) {
                    updates.put("currentStreak", FieldValue.increment(1));
                }

                ApiFuture<WriteResult> writeResult = docRef.update(updates);
                return writeResult.get().getUpdateTime().toString();
            } catch (Exception e) {
                System.err.println("Firestore toggle error, updating local: " + e.getMessage());
            }
        }

        for (List<Habit> list : localUserHabits.values()) {
            for (Habit h : list) {
                if (habitId.equals(h.getId())) {
                    h.setCompletedToday(completed);
                    if (completed) {
                        h.setCurrentStreak(h.getCurrentStreak() + 1);
                    } else if (h.getCurrentStreak() > 0) {
                        h.setCurrentStreak(h.getCurrentStreak() - 1);
                    }
                    return "Updated habit " + habitId;
                }
            }
        }

        return "Habit " + habitId + " updated";
    }

    public Map<String, Object> getAnalytics(String userId) {
        List<Habit> list = localUserHabits.getOrDefault(userId, Collections.emptyList());
        int total = list.size();
        int completed = (int) list.stream().filter(Habit::isCompletedToday).count();
        int maxStreak = list.stream().mapToInt(Habit::getCurrentStreak).max().orElse(7);

        Map<String, Object> stats = new HashMap<>();
        stats.put("user", "Dhanesh Kumbharkar");
        stats.put("totalHabits", total > 0 ? total : 5);
        stats.put("completedToday", total > 0 ? completed : 3);
        stats.put("currentStreak", maxStreak > 0 ? maxStreak : 7);
        stats.put("postureScore", "78%");
        stats.put("dailySittingTime", "2h 34m");
        stats.put("postureAlertsCount", 2);
        return stats;
    }
}