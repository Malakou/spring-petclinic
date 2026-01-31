# syntax=docker/dockerfile:1.5

FROM eclipse-temurin:17-jdk AS builder
WORKDIR /build

# 1) Copier juste le nécessaire pour maximiser le cache
COPY mvnw pom.xml ./
COPY .mvn .mvn

# 2) Pré-charger les dépendances Maven (cache partagé)
RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw -DskipTests -q dependency:go-offline

# 3) Copier le reste du code puis builder
COPY . .
RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw -DskipTests clean package

FROM eclipse-temurin:17-jre

# curl pour le healthcheck HTTP
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /build/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
