# AlignX - Smart Habit & Posture Alignment Tracker

AlignX is a full-stack health and posture alignment platform featuring a Flutter frontend and Spring Boot backend connected to Firebase Admin SDK / Firestore.

---

## 🚀 Features

- **Authentication System**:
  - **Login & Sign Up**: Responsive auth screen with form validation, password visibility toggle, and error handling.
  - **Session Persistence**: Powered by `SharedPreferences` and backend auth tokens.
  - **Logout Flow**: Prominent logout action in the app bar with confirmation modal to prevent accidental sign-outs.
- **Posture Analytics Dashboard**: Real-time habit streak tracking, daily sitting time, and posture score indicator.
- **Pelvic Tilt & Posture Exercises**: Dedicated guidance for Anterior Pelvic Tilt (APT) stretches and corrective routines.
- **Posture Timer & Guide**: Integrated desk timer and onboarding guidelines.
- **Unified Full-Stack Deployment**: The Flutter release web app is served directly from Spring Boot on port `8085`.

---

## 🔑 Default Test Accounts

| Name | Email | Password | Role |
| :--- | :--- | :--- | :--- |
| **Dhanesh Kumbharkar** | `dhanesh@alignx.com` | `password123` | Default User |
| **Demo User** | `demo@alignx.com` | `alignx2026` | Explorer |

> You can also register any new account directly via the **Create Account** tab!

---

## 🌐 Live Local Deployment

The application is deployed and running live locally:
- **Web App URL**: [http://localhost:8085](http://localhost:8085)
- **API Health**: [http://localhost:8085/api/health](http://localhost:8085/api/health)
- **Habit Analytics**: [http://localhost:8085/api/habits/analytics](http://localhost:8085/api/habits/analytics)
- **Posture Exercises**: [http://localhost:8085/api/exercises/posture](http://localhost:8085/api/exercises/posture)

---

## 🛠️ How to Run & Deploy

### One-Click Deploy Script (PowerShell):
```powershell
.\deploy.ps1
```

### Manual Run:
```powershell
# 1. Build Flutter Web
cd alignx_frontend
flutter build web --release

# 2. Copy to Spring Boot static resources
Copy-Item -Path "build\web\*" -Destination "..\alignx_backend\src\main\resources\static" -Recurse -Force

# 3. Package and Run Spring Boot
cd ..\alignx_backend
.\mvnw.cmd clean package -DskipTests
java -jar target\alignx_backend-0.0.1-SNAPSHOT.jar
```
Open [http://localhost:8085](http://localhost:8085) in your web browser.
