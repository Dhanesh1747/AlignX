package com.alignx.alignx_backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    private static boolean firebaseInitialized = false;

    public static boolean isFirebaseInitialized() {
        return firebaseInitialized;
    }

    @PostConstruct
    public void initializeFirebase() {
        if (!FirebaseApp.getApps().isEmpty()) {
            firebaseInitialized = true;
            return;
        }

        try {
            InputStream serviceAccount = null;
            try {
                serviceAccount = new ClassPathResource("serviceAccountKey.json").getInputStream();
            } catch (Exception e1) {
                try {
                    serviceAccount = new ClassPathResource("serviceAccountKey.json.json").getInputStream();
                } catch (Exception e2) {
                    // File not in resources
                }
            }

            if (serviceAccount != null) {
                FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

                FirebaseApp.initializeApp(options);
                firebaseInitialized = true;
                System.out.println("✅ Firebase Admin SDK successfully initialized!");
            } else {
                System.out.println("ℹ️ serviceAccountKey.json not present. Running with hybrid local persistence.");
            }
        } catch (Exception e) {
            System.err.println("⚠️ Firebase initialization note: " + e.getMessage());
            System.out.println("ℹ️ Running with hybrid local persistence.");
        }
    }
}
