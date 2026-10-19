# ==========================================
# Stage 1: Build Full-Stack Spring Boot JAR
# ==========================================
FROM maven:3.9.6-eclipse-temurin-21-alpine AS builder
WORKDIR /build

# Copy backend POM and source code (including static Flutter web assets)
COPY alignx_backend/pom.xml .
COPY alignx_backend/src ./src

# Build production JAR skipping test phase
RUN mvn clean package -DskipTests

# ==========================================
# Stage 2: Minimal Production JRE Runtime
# ==========================================
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Copy executable jar from builder
COPY --from=builder /build/target/alignx_backend-0.0.1-SNAPSHOT.jar app.jar

# Copy service account key if available
COPY alignx_backend/src/main/resources/serviceAccountKey.json* ./

# Default fallback port (overridden dynamically by Render / Railway)
EXPOSE 8085
ENV PORT=8085

# Start Spring Boot binding to dynamic cloud PORT
ENTRYPOINT ["sh", "-c", "java -Dserver.port=${PORT} -jar app.jar"]

