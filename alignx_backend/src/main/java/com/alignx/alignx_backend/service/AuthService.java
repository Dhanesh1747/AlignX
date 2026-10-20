package com.alignx.alignx_backend.service;

import com.alignx.alignx_backend.model.AppUser;
import com.alignx.alignx_backend.model.AuthSession;
import com.alignx.alignx_backend.model.Habit;
import com.alignx.alignx_backend.repository.AppUserRepository;
import com.alignx.alignx_backend.repository.AuthSessionRepository;
import com.alignx.alignx_backend.repository.HabitRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.regex.Pattern;

@Service
public class AuthService {
    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final AppUserRepository users;
    private final AuthSessionRepository sessions;
    private final HabitRepository habits;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public AuthService(AppUserRepository users, AuthSessionRepository sessions, HabitRepository habits) {
        this.users = users;
        this.sessions = sessions;
        this.habits = habits;
    }

    @Transactional
    public AuthSessionResponse register(String name, String email, String password) {
        String cleanName = name == null ? "" : name.trim();
        String cleanEmail = normalizeEmail(email);
        if (cleanName.length() < 2 || cleanName.length() > 120) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Name must be between 2 and 120 characters.");
        }
        if (!EMAIL_PATTERN.matcher(cleanEmail).matches()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Enter a valid email address.");
        }
        if (password == null || password.length() < 8
                || password.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Password must be between 8 and 72 characters.");
        }
        if (users.existsByEmailIgnoreCase(cleanEmail)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "An account already exists for this email.");
        }

        AppUser user = users.save(new AppUser(cleanEmail, cleanName, passwordEncoder.encode(password)));
        seedStarterHabits(user.getId());
        return createSession(user);
    }

    @Transactional
    public AuthSessionResponse login(String email, String password) {
        String cleanEmail = normalizeEmail(email);
        AppUser user = users.findByEmailIgnoreCase(cleanEmail)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email or password is incorrect."));
        if (password == null || password.getBytes(StandardCharsets.UTF_8).length > 72
                || !passwordEncoder.matches(password, user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email or password is incorrect.");
        }
        return createSession(user);
    }

    @Transactional(readOnly = true)
    public Optional<AppUser> authenticate(String token) {
        if (token == null || token.isBlank()) return Optional.empty();
        return sessions.findByTokenHashAndExpiresAtAfter(hashToken(token), Instant.now())
                .flatMap(session -> users.findById(session.getUserId()));
    }

    @Transactional
    public void logout(String token) {
        if (token != null && !token.isBlank()) {
            String tokenHash = hashToken(token);
            sessions.findById(tokenHash).ifPresent(sessions::delete);
        }
    }

    private AuthSessionResponse createSession(AppUser user) {
        byte[] tokenBytes = new byte[32];
        SECURE_RANDOM.nextBytes(tokenBytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(tokenBytes);
        Instant now = Instant.now();
        sessions.save(new AuthSession(hashToken(token), user.getId(), now, now.plus(7, ChronoUnit.DAYS)));
        return new AuthSessionResponse(token, user.getId(), user.getName(), user.getEmail());
    }

    private void seedStarterHabits(String userId) {
        habits.saveAll(List.of(
                new Habit(null, userId, "Sit up straight & engage core", "Posture", 0, false, null),
                new Habit(null, userId, "Hip Flexor Lunge Stretch", "APT Alignment", 0, false, null),
                new Habit(null, userId, "Drink 3L Water", "Hydration", 0, false, null),
                new Habit(null, userId, "5-Minute Standing Break", "Movement", 0, false, null),
                new Habit(null, userId, "Glute Bridges (15 reps)", "APT Alignment", 0, false, null)
        ));
    }

    private String normalizeEmail(String email) {
        return email == null ? "" : email.trim().toLowerCase(Locale.ROOT);
    }

    private String hashToken(String token) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (Exception exception) {
            throw new IllegalStateException("SHA-256 is not available", exception);
        }
    }

    public record AuthSessionResponse(String token, String userId, String name, String email) { }
}
