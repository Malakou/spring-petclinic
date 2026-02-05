pipeline {

    // Le pipeline peut s’exécuter sur n’importe quel agent Jenkins disponible
    agent any

    environment {

        // Activation de Docker BuildKit pour améliorer les performances de build
        // (cache Maven notamment avec les Dockerfiles multi-stage)
        DOCKER_BUILDKIT = "1"
        COMPOSE_DOCKER_CLI_BUILD = "1"

        // Variable de contrôle :
        // true  -> les conteneurs restent actifs après la fin du pipeline
        // false -> les conteneurs sont supprimés automatiquement
        KEEP_RUNNING = "true"
    }

    stages {

        stage("Checkout") {
            steps {
                // Récupération du code source depuis le dépôt Git configuré dans Jenkins
                checkout scm
            }
        }

        stage("Build images from docker compose") {
            steps {
                sh """
                    set -e

                    echo "=== Docker versions ==="
                    docker --version
                    docker compose --version

                    echo "=== Build des images Docker via docker compose ==="
                    // Construction des images définies dans docker-compose.yml
                    docker compose build
                """
            }
        }

        stage("Run stack") {
            steps {
                sh """
                    set -e

                    echo "=== Démarrage des conteneurs ==="
                    // Lancement de l'application et de la base de données en arrière-plan
                    docker compose up -d

                    echo "=== État des conteneurs ==="
                    docker compose ps
                """
            }
        }

        stage("Wait for health + Smoke test") {
            steps {
                sh """
                    set -e

                    echo "=== Attente du healthcheck de Petclinic ==="

                    // Récupération de l’ID du conteneur petclinic
                    PET_ID=\$(docker compose ps -q petclinic)

                    if [ -z "\$PET_ID" ]; then
                      echo "Petclinic container not found"
                      exit 1
                    fi

                    echo "Petclinic container ID: \$PET_ID"
                    echo "Waiting for health=healthy (max 180s)..."

                    // Boucle d’attente du statut healthy (max 180 secondes)
                    for i in \$(seq 1 90); do
                      STATUS=\$(docker inspect -f '{{.State.Health.Status}}' \$PET_ID)
                      echo "Health status: \$STATUS"

                      if [ "\$STATUS" = "healthy" ]; then
                        break
                      fi

                      sleep 2
                    done

                    STATUS=\$(docker inspect -f '{{.State.Health.Status}}' \$PET_ID)

                    if [ "\$STATUS" != "healthy" ]; then
                      echo "Petclinic did not become healthy"
                      exit 1
                    fi

                    echo "Petclinic is healthy"
                    echo "=== Smoke test HTTP depuis le conteneur ==="

                    // Test HTTP exécuté depuis le conteneur pour éviter les problèmes réseau Jenkins/host
                    docker exec \$PET_ID curl -fsS http://localhost:8080/

                    echo "Smoke test OK"
                """
            }
        }
    }

    post {
        always {

            // Affichage des logs pour faciliter le debug en cas d’échec
            sh """
                echo "=== Logs (last 100 lines) ==="
                docker compose logs --tail=100 || true
            """

            script {
                if (env.KEEP_RUNNING == "true") {
                    echo "KEEP_RUNNING=true : les conteneurs restent actifs"
                    echo "Application accessible sur : http://localhost:9123"
                } else {
                    echo "KEEP_RUNNING=false : nettoyage des conteneurs"
                    sh "docker compose down -v --remove-orphans"
                }
            }
        }
    }
}
