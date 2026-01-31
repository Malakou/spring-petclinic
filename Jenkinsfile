pipeline {
  agent any

  environment {
    DOCKER_BUILDKIT = "1"
    COMPOSE_DOCKER_CLI_BUILD = "1"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build images from docker-compose') {
      steps {
        sh 'docker --version'
        sh 'docker-compose --version'
        sh 'docker-compose build'
      }
    }

    stage('Smoke test') {
      steps {
        sh 'docker-compose up -d'
        sh 'docker-compose ps'
        sh 'curl -fsS http://localhost:9123/ >/dev/null'
      }
      post {
        always {
          sh 'docker-compose logs --tail=200 || true'
          sh 'docker-compose down -v --remove-orphans || true'
        }
      }
    }
  }
}
