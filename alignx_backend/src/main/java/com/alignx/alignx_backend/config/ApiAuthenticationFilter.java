package com.alignx.alignx_backend.config;

import com.alignx.alignx_backend.model.AppUser;
import com.alignx.alignx_backend.service.AuthService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class ApiAuthenticationFilter extends OncePerRequestFilter {
    public static final String USER_ATTRIBUTE = "alignxAuthenticatedUser";

    private final AuthService authService;

    public ApiAuthenticationFilter(AuthService authService) {
        this.authService = authService;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        String method = request.getMethod();
        return method.equals("OPTIONS")
                || path.equals("/test") || path.equals("/api/test")
                || path.startsWith("/api/exercises/")
                || (path.equals("/api/auth/register") && method.equals("POST"))
                || (path.equals("/api/auth/login") && method.equals("POST"));
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String path = request.getRequestURI();
        boolean protectedPath = path.equals("/api/auth/me")
                || path.equals("/api/auth/logout")
                || path.equals("/api/habits")
                || path.startsWith("/api/habits/")
                || path.equals("/api/goals")
                || path.startsWith("/api/goals/");

        if (!protectedPath) {
            chain.doFilter(request, response);
            return;
        }

        String authorization = request.getHeader("Authorization");
        String token = authorization != null && authorization.startsWith("Bearer ")
                ? authorization.substring(7).trim()
                : null;
        AppUser user = authService.authenticate(token).orElse(null);
        if (user == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.getWriter().write("{\"message\":\"Your session has expired. Please sign in again.\"}");
            return;
        }

        request.setAttribute(USER_ATTRIBUTE, user);
        chain.doFilter(request, response);
    }
}
