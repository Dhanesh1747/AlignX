package com.alignx.alignx_backend.service;

import com.alignx.alignx_backend.model.Habit;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
public class HabitService {

    private static final String COLLECTION_NAME = "habits";

    // Fetch all habits for a given user from Firestore
    public List<Habit> getUserHabits(String userId) throws ExecutionException, InterruptedException {
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
        return habitList;
    }

    // Save a new habit in Firestore
    public String saveHabit(Habit habit) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        ApiFuture<DocumentReference> addedDocRef = db.collection(COLLECTION_NAME).add(habit);
        return addedDocRef.get().getId();
    }

    // Toggle completion state and increment streak
    public String toggleHabitCompletion(String habitId, boolean completed) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference docRef = db.collection(COLLECTION_NAME).document(habitId);

        Map<String, Object> updates = new HashMap<>();
        updates.put("completedToday", completed);
        if (completed) {
            updates.put("currentStreak", FieldValue.increment(1));
        }

        ApiFuture<WriteResult> writeResult = docRef.update(updates);
        return writeResult.get().getUpdateTime().toString();
    }
}