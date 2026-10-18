package com.alignx.alignx_backend;

import com.google.api.core.ApiFuture;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.*;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
public class FirestoreService {

    private Firestore getDatabaseInstance() {
        if (FirebaseApp.getApps().isEmpty()) {
            try {
                InputStream serviceAccount;
                try {
                    serviceAccount = new ClassPathResource("serviceAccountKey.json").getInputStream();
                } catch (Exception e) {
                    // Fallback if Windows added a double .json extension
                    serviceAccount = new ClassPathResource("serviceAccountKey.json.json").getInputStream();
                }

                FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

                FirebaseApp.initializeApp(options);
                System.out.println("✅ Firebase initialized successfully!");
            } catch (Exception e) {
                System.err.println("❌ Firebase error: " + e.getMessage());
                throw new RuntimeException("Failed to initialize Firebase: " + e.getMessage());
            }
        }
        return FirestoreClient.getFirestore();
    }

    public String saveHabit(String userId, String title, String category) throws ExecutionException, InterruptedException {
        Firestore db = getDatabaseInstance();
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
        Firestore db = getDatabaseInstance();
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