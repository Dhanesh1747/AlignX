# AlignX 🚀

Smart habit and posture tracking full-stack platform built with **Flutter**, **Spring Boot 3.2**, and **MySQL**.

AlignX helps users balance daily productivity with overall wellbeing through posture break alerts, habit tracking, daily and weekly goals, and guided posture exercises.

---

## 🏗️ Architecture Overview

```
AlignX/
├── alignx_backend/               # Spring Boot 3.2 (Java 17/21) REST Backend (Port 8081)
│   ├── src/main/java/com/alignx/alignx_backend/
│   │   ├── AlignxBackendApplication.java
│   │   ├── config/ApiAuthenticationFilter.java
│   │   ├── controller/
│   │   │   ├── HealthController.java    # /test and /api/test health checks
│   │   │   ├── AuthController.java       # Register, login, logout, current session
│   │   │   ├── HabitController.java     # /api/habits, /analytics, /user/{id}, toggle
│   │   │   ├── GoalController.java      # Daily and weekly goals and progress
│   │   │   └── ExerciseController.java  # /api/exercises/posture
│   │   ├── model/                        # User, session, habit, and goal entities
│   │   ├── repository/                   # Spring Data JPA repositories
│   │   └── service/                      # MySQL persistence and authentication
│   └── pom.xml
│
└── alignx_frontend/              # Flutter 3.x Cross-Platform Client (Web, Android, Desktop)
    ├── lib/
    │   ├── main.dart
    │   ├── models/
    │   │   ├── habit_model.dart
    │   │   ├── goal_model.dart
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

### 1. Start MySQL

Use an existing MySQL Server on `localhost:3306`, or start the bundled database with Docker Desktop from the project root:
```powershell
docker compose up -d mysql
```
For an existing MySQL Server, run this once in MySQL Workbench while connected as an administrator:
```sql
CREATE DATABASE IF NOT EXISTS alignx_db;
CREATE USER IF NOT EXISTS 'alignx_user'@'localhost' IDENTIFIED BY 'alignx_dev_password';
ALTER USER 'alignx_user'@'localhost' IDENTIFIED BY 'alignx_dev_password';
GRANT ALL PRIVILEGES ON alignx_db.* TO 'alignx_user'@'localhost';
```

### 2. Run the Backend (Spring Boot)

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

### 3. Run the Frontend (Flutter)

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
| `POST` | `/api/auth/register` | Create account and start a session |
| `POST` | `/api/auth/login` | Sign in and receive a session token |
| `GET` | `/api/auth/me` | Return the signed-in account (Bearer token required) |
| `POST` | `/api/auth/logout` | Revoke the current session (Bearer token required) |
| `GET` | `/api/habits/analytics` | Overall user analytics (score, streaks, sitting time) |
| `GET` | `/api/habits/user/{userId}` | Fetch all habits for a specific user |
| `POST` | `/api/habits` | Create a new habit (JSON body: `Habit`) |
| `PUT` | `/api/habits/{id}/toggle?completed=true` | Toggle habit completion and increment streak |
| `GET` | `/api/goals` | Fetch the signed-in user's goals; reset expired daily or weekly progress |
| `POST` | `/api/goals` | Create a daily or weekly Health or Productivity goal |
| `POST` | `/api/goals/{id}/progress` | Add one progress unit to a goal owned by the signed-in user |
| `GET` | `/api/exercises/posture` | Fetch posture & Anterior Pelvic Tilt corrective routines |

---

## MySQL and Login Setup

The backend uses MySQL at `localhost:3306`. Use an installed MySQL Server, or start the bundled database with Docker Desktop:

```powershell
docker compose up -d mysql
```

The backend creates its tables on startup. The local development database is `alignx_db`; the default credentials are configured for the included Compose service. For an existing MySQL installation with different credentials, set `DB_URL`, `DB_USERNAME`, and `DB_PASSWORD` before starting the backend. The `app_users`, `auth_sessions`, `habits`, and `goals` tables hold registered accounts, revocable login sessions, habits, and user goals. Passwords are BCrypt-hashed; session tokens are stored as SHA-256 hashes and expire after seven days.

Goals are scoped to the signed-in account. Each goal has a title, a `HEALTH` or `PRODUCTIVITY` category, a `DAILY` or `WEEKLY` period, and a target count. Daily progress resets when the date changes; weekly progress resets at the start of Monday.

Sign up in the app to create the first account. It receives starter habits automatically. Existing data in Firestore is not copied automatically; export/import it separately before removing the old Firebase project if you need to keep those records.

---

## Jenkins CI

The repository-root `Jenkinsfile` checks out `main`, verifies and packages the Spring Boot backend, analyzes and builds the Flutter web app, and archives the JAR and web files. The package-level Jenkinsfile is kept in sync for jobs that explicitly use that script path. This web pipeline does not require Android Studio or the Android SDK.

### Jenkins agent requirements

- Java 17 or newer, Git, and Flutter must be installed and available on the agent's `PATH`.
- The Jenkins agent account must be able to write to its workspace.

### Create the Pipeline job

1. In Jenkins, choose **New Item**, enter a job name, select **Pipeline**, then choose **OK**.
2. Under **Pipeline**, set **Definition** to **Pipeline script** and paste the contents of the repository-root `Jenkinsfile` into the script box. This works before the local Jenkinsfile changes are pushed to GitHub.
3. Save the job and choose **Build Now**. The `Frontend: Build Web` stage produces `alignx_frontend/build/web/`; Jenkins archives these files and the backend JAR under the build's **Artifacts** section.

After the Jenkinsfile has been committed and pushed to GitHub, you can instead select **Pipeline script from SCM**, choose Git, enter `https://github.com/Dhanesh1747/AlignX.git`, set the branch to `*/main`, and use `Jenkinsfile` as the script path.

For a private repository, configure Jenkins credentials and select them in the SCM section instead of putting a token in the Jenkinsfile.

## GitHub Actions CI

The `.github/workflows/ci.yml` workflow runs on pushes and pull requests targeting `main`, and can also be started manually from the repository's **Actions** tab. It runs backend tests and packaging with Maven, then analyzes Flutter and builds the web app. The separate `deploy.yml` workflow publishes the Flutter web build to GitHub Pages after pushes to `main`.
