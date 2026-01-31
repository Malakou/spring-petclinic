pipeline {
  agent any

  environment {
    DOCKER_BUILDKIT = "1"
    COMPOSE_DOCKER_CLI_BUILD = "1"
  }

  options {
    timestamps()
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build images from docker-compose') {
      steps {
        sh '''
          set -e
          docker --version
          docker-compose --version
          docker-compose build
        '''
      }
    }

    stage('Run stack') {
      steps {
        sh '''
          set -e
          docker-compose up -d
          docker-compose ps
        '''
      }
    }

    stage('Wait for health + Smoke test') {
      steps {
        sh '''
          set -e

          PET_ID=$(docker-compose ps -q petclinic)
          if [ -z "$PET_ID" ]; then
            echo "ERROR: petclinic container not found"
            docker-compose ps
            exit 1
          fi

          echo "Waiting for petclinic health=healthy (max 180s)..."
          for i in $(seq 1 90); do
            STATUS=$(docker inspect -f '{{.State.Health.Status}}' "$PET_ID" 2>/dev/null || echo "starting")
            echo "Health status: $STATUS"
            if [ "$STATUS" = "healthy" ]; then
              break
            fi
            sleep 2
          done

          STATUS=$(docker inspect -f '{{.State.Health.Status}}' "$PET_ID" 2>/dev/null || echo "unknown")
          if [ "$STATUS" != "healthy" ]; then
            echo "ERROR: petclinic never became healthy"
            docker-compose ps
            docker-compose logs --tail=200 petclinic || true
            exit 1
          fi

          echo "Petclinic is healthy, running HTTP check..."
          curl -fsS http://localhost:9123/ >/dev/null
          echo "✅ Smoke test OK"
        '''
      }
    }
  }

  post {
    always {
      sh '''
        docker-compose logs --tail=200 || true
        docker-compose down -v --remove-orphans || true
      '''
    }
  }
}
