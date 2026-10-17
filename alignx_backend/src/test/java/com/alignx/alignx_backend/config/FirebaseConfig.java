package com.alignx.alignx_backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import javax.annotation.PostConstruct;
import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void initializeFirebase() {
        try {
            InputStream serviceAccount = 
                new ClassPathResource("serviceAccountKey.json").getInputStream();

            FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                System.out.println("✅ Firebase Admin SDK successfully initialized!");
            }
        } catch (Exception e) {
            System.err.println("❌ Error initializing Firebase: " + e.getMessage());
            e.printStackTrace();
        }
    }
}