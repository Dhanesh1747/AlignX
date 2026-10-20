# AlignX Frontend (Flutter App)

The app uses a Spring Boot REST API for account registration, login/logout, and habit data. Authentication sessions are persisted by the backend in MySQL; the web client retains the issued session token using shared preferences.

## Run the app

1. Start MySQL from the project root with `docker compose up -d mysql`.
2. Start the API in `alignx_backend` with `mvn spring-boot:run`.
3. In this folder, run `flutter pub get` and then `flutter run -d chrome`.

The API defaults to `http://localhost:8081/api`. Android emulators use `http://10.0.2.2:8081/api`.

Create an account from the sign-in page. Passwords must be at least eight characters. The backend creates starter habits for a new account. Email-based password recovery is not configured; use an administrator-managed database reset if a demo password is lost.

The focus timer shows an in-app posture reminder every five minutes by default. Turn off **5-minute posture alerts** to receive only the selected timer's completion alert.
