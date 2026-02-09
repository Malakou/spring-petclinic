# ============================================================================
# Dockerfile – Application Spring Petclinic
#
# Ce Dockerfile permet de construire et d’exécuter l’application Spring
# Petclinic dans un conteneur Docker.
#
# Il utilise une approche multi-stage :
#  - une première image sert à compiler l’application avec Maven
#  - une seconde image plus légère sert uniquement à l’exécution
#
# Ce Dockerfile est utilisé :
#  - par docker-compose pour lancer l’application avec MySQL
#  - par Jenkins dans la pipeline CI/CD pour automatiser le build
# ============================================================================


# Active les fonctionnalités avancées de Docker BuildKit (cache, mounts, etc.)
# Cela permet notamment d’accélérer les builds Maven
# syntax=docker/dockerfile:1.5


# =========================
# Étape 1 : Build Maven
# =========================

# Image Java avec JDK (nécessaire pour compiler le projet)
FROM eclipse-temurin:17-jdk AS builder

# Répertoire de travail pour la phase de build
WORKDIR /build

# Copie des fichiers Maven nécessaires au téléchargement des dépendances
# Cette étape est séparée pour profiter du cache Docker
COPY mvnw pom.xml ./
COPY .mvn .mvn

# Téléchargement des dépendances Maven en mode offline
# Le cache ~/.m2 est conservé grâce à BuildKit pour accélérer les builds suivants
RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw -DskipTests -q dependency:go-offline

# Copie de l’ensemble du code source du projet
COPY . .

# Compilation de l’application et génération du fichier JAR
# Les tests sont ignorés pour accélérer le build en CI
RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw -DskipTests clean package


# =========================
# Étape 2 : Image finale
# =========================

# Image Java plus légère (JRE uniquement) pour l’exécution
FROM eclipse-temurin:17-jre

# Répertoire de travail de l’application
WORKDIR /app

# Installation de dépendances système minimales
# curl est utilisé pour le healthcheck dans docker-compose
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Création d’un utilisateur applicatif non-root
# Bonne pratique de sécurité : éviter l’exécution en root
RUN useradd --system --uid 1001 --create-home appuser \
 && chown -R appuser:appuser /app

# Copie du JAR généré depuis l’étape "builder" vers l’image finale
COPY --from=builder /build/target/*.jar /app/app.jar

# Attribution des droits sur le fichier JAR
RUN chown appuser:appuser /app/app.jar

# Exposition du port utilisé par Spring Boot
EXPOSE 8080

# Exécution de l’application avec l’utilisateur non-root
USER appuser

# Commande de démarrage du conteneur (forme exec recommandée)
ENTRYPOINT ["java","-jar","/app/app.jar"]
