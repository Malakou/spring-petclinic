pipeline {

    agent any

    environment {

        // ✅ Active BuildKit (important pour cache Maven)
        DOCKER_BUILDKIT = "1"
        COMPOSE_DOCKER_CLI_BUILD = "1"

        // 🔥 Switch :
        // true  = conteneurs restent actifs après pipeline
        // false = nettoyage automatique
        KEEP_RUNNING = "true"
    }

    stages {

        stage("Checkout") {
            steps {
                checkout scm
            }
        }

        stage("Build images from docker-compose") {
            steps {
                sh """
                    set -e

                    echo "=== Docker versions ==="
                    docker --version
                    docker-compose --version

                    echo "=== Build images (BuildKit ON) ==="
                    docker-compose build
                """
            }
        }

        stage("Run stack") {
            steps {
                sh """
                    set -e
                    echo "=== Start containers ==="
                    docker-compose up -d

                    echo "=== Containers status ==="
                    docker-compose ps
                """
            }
        }

        stage("Wait for health + Smoke test") {
            steps {
                sh """
                    set -e

                    echo "=== Waiting for Petclinic health ==="

                    PET_ID=\$(docker-compose ps -q petclinic)

                    if [ -z "\$PET_ID" ]; then
                      echo "❌ Petclinic container not found"
                      exit 1
                    fi

                    echo "Petclinic container ID: \$PET_ID"
                    echo "Waiting for health=healthy (max 180s)..."

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
                      echo "❌ Petclinic did not become healthy"
                      exit 1
                    fi

                    echo "✅ Petclinic is healthy!"
                    echo "=== Smoke test HTTP inside container ==="

                    docker exec \$PET_ID curl -fsS http://localhost:8080/

                    echo "✅ Smoke test OK"
                """
            }
        }
    }

    post {
        always {

            sh """
                echo "=== Logs (last 100 lines) ==="
                docker-compose logs --tail=100 || true
            """

            script {
                if (env.KEEP_RUNNING == "true") {
                    echo "🔥 KEEP_RUNNING=true → containers are kept running"
                    echo "➡️ Open in browser: http://localhost:9123"
                } else {
                    echo "🧹 KEEP_RUNNING=false → cleaning containers..."
                    sh "docker-compose down -v --remove-orphans"
                }
            }
        }
    }
}
