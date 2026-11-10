# syntax=docker/dockerfile:1
# --- Stage 1: build ---
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /workspace

COPY mvnw ./
COPY .mvn ./.mvn
COPY pom.xml lombok.config ./
COPY domain ./domain
COPY infrastructure ./infrastructure
COPY application ./application
COPY coverage-report ./coverage-report

# Empaqueta el jar ejecutable sin correr tests en la imagen (los tests corren en CI).
RUN chmod +x mvnw && ./mvnw -q -pl application/app-service -am clean package -DskipTests

# --- Stage 2: runtime (non-root) ---
FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app

RUN addgroup -S app && adduser -S app -G app
COPY --from=build /workspace/application/app-service/target/*.jar app.jar
USER app

EXPOSE 8080
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0"
ENTRYPOINT ["java", "-jar", "app.jar"]
