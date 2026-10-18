# AlignX 🚀

Smart habit and posture tracking full-stack platform built with **Flutter**, **Spring Boot 3.2**, and **Firebase**.

AlignX is designed to combat forward head posture, slouching, and Anterior Pelvic Tilt (APT) through smart posture break alerts, habit streaks, sitting time telemetry, and guided physical corrective exercises.

---

## 🏗️ Architecture Overview

```
AlignX/
├── alignx_backend/               # Spring Boot 3.2 (Java 17/21) REST Backend (Port 8081)
│   ├── src/main/java/com/alignx/alignx_backend/
│   │   ├── AlignxBackendApplication.java
│   │   ├── config/FirebaseConfig.java
│   │   ├── controller/
│   │   │   ├── HabitController.java     # /api/habits, /analytics, /user/{id}, toggle
│   │   │   └── ExerciseController.java  # /api/exercises/posture
│   │   ├── model/Habit.java
│   │   └── service/HabitService.java    # Hybrid Firestore & In-Memory persistence
│   └── pom.xml
│
└── alignx_frontend/              # Flutter 3.x Cross-Platform Client (Web, Android, Desktop)
    ├── lib/
    │   ├── main.dart
    │   ├── models/
    │   │   ├── habit_model.dart
    │   │   └── exercise_model.dart
    │   ├── screens/
    │   │   ├── dashboard_screen.dart    # Analytics, habit checklist, posture score
    │   │   ├── exercises_screen.dart    # APT and posture alignment exercise guides
    │   │   ├── timer_screen.dart        # Sitting time interval and break timer
    │   │   └── onboarding_screen.dart
    │   └── services/api_service.dart    # Connects to http://localhost:8081/api
    └── pubspec.yaml
```

---

## ⚡ Quick Start

### 1. Run the Backend (Spring Boot)

Open a terminal in `alignx_backend`:
```powershell
mvn clean spring-boot:run
```
Or run the packaged JAR:
```powershell
java -jar target/alignx_backend-0.0.1-SNAPSHOT.jar
```
* **Base URL:** `http://localhost:8081`
* **Health Check:** `http://localhost:8081/test`

### 2. Run the Frontend (Flutter)

Open a terminal in `alignx_frontend`:
```powershell
flutter pub get
flutter run -d chrome
```
*(You can also run `-d windows` or `-d edge` or an Android device/emulator).*

---

## 🔌 API Endpoints Reference

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/test` or `/api/test` | Backend health check status |
| `GET` | `/api/habits/analytics` | Overall user analytics (score, streaks, sitting time) |
| `GET` | `/api/habits/user/{userId}` | Fetch all habits for a specific user |
| `POST` | `/api/habits` | Create a new habit (JSON body: `Habit`) |
| `PUT` | `/api/habits/{id}/toggle?completed=true` | Toggle habit completion and increment streak |
| `GET` | `/api/exercises/posture` | Fetch posture & Anterior Pelvic Tilt corrective routines |

---

## ☁️ Firebase Firestore Setup (Optional)
The backend is built with a **Hybrid Persistence Engine**:
- **Out of the box**: Runs locally with pre-seeded data in thread-safe memory so you can develop and test immediately without configuring cloud credentials.
- **Production mode**: Place your Firebase service account key named `serviceAccountKey.json` inside `alignx_backend/src/main/resources/`. The backend will automatically detect it on startup and switch to live cloud Firestore storage!
