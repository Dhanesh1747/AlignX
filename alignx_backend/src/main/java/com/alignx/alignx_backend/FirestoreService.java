package com.alignx.alignx_backend;

import com.alignx.alignx_backend.config.FirebaseConfig;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
public class FirestoreService {

    public String saveHabit(String userId, String title, String category) throws ExecutionException, InterruptedException {
        if (!FirebaseConfig.isFirebaseInitialized()) {
            return "local_" + UUID.randomUUID().toString();
        }

        Firestore db = FirestoreClient.getFirestore();
        Map<String, Object> habitData = new HashMap<>();
        habitData.put("userId", userId);
        habitData.put("title", title);
        habitData.put("category", category);
        habitData.put("completedToday", false);
        habitData.put("currentStreak", 0);
        habitData.put("createdAt", FieldValue.serverTimestamp());

        ApiFuture<DocumentReference> addedDocRef = db.collection("habits").add(habitData);
        return addedDocRef.get().getId();
    }

    public List<Map<String, Object>> getUserHabits(String userId) throws ExecutionException, InterruptedException {
        if (!FirebaseConfig.isFirebaseInitialized()) {
            return Collections.emptyList();
        }

        Firestore db = FirestoreClient.getFirestore();
        CollectionReference habits = db.collection("habits");
        Query query = habits.whereEqualTo("userId", userId);
        ApiFuture<QuerySnapshot> querySnapshot = query.get();

        List<Map<String, Object>> habitList = new ArrayList<>();
        for (DocumentSnapshot doc : querySnapshot.get().getDocuments()) {
            Map<String, Object> data = doc.getData();
            if (data != null) {
                data.put("id", doc.getId());
                habitList.add(data);
            }
        }
        return habitList;
    }
}