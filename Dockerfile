# syntax=docker/dockerfile:1.5

FROM eclipse-temurin:17-jdk AS builder
WORKDIR /build

COPY mvnw pom.xml ./
COPY .mvn .mvn

RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw -DskipTests -q dependency:go-offline

COPY . .
RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw -DskipTests clean package


FROM eclipse-temurin:17-jre

# Dossier dédié à l'application
WORKDIR /app

# Dépendance nécessaire pour le healthcheck docker-compose (curl)
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Création d'un utilisateur applicatif non-root
RUN useradd --system --uid 1001 --create-home appuser \
 && chown -R appuser:appuser /app

# Copie du jar et attribution des droits
COPY --from=builder /build/target/*.jar /app/app.jar
RUN chown appuser:appuser /app/app.jar

# Exposition du port
EXPOSE 8080

# Exécution avec l'utilisateur applicatif
USER appuser

# Exec form (bonne pratique)
ENTRYPOINT ["java","-jar","/app/app.jar"]
