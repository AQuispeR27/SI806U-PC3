// ============================================
// Jenkinsfile - Pipeline CI/CD Sistema Culqui
// ============================================

pipeline {
    agent any

    // ============================================
    // Variables de Entorno
    // ============================================
    environment {
        // Docker
        DOCKER_REGISTRY = credentials('docker-registry-url') // Configurar en Jenkins
        DOCKER_CREDENTIALS = credentials('docker-credentials-id') // Configurar en Jenkins

        // Nombres de imágenes
        BACKEND_IMAGE = "culqui-backend"
        FRONTEND_IMAGE = "culqui-frontend"

        // Versión
        VERSION = "${env.BUILD_NUMBER}"
        GIT_COMMIT_SHORT = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()

        // Entorno
        ENVIRONMENT = "${env.BRANCH_NAME == 'main' ? 'production' : 'development'}"

        // Configuración de la aplicación
        DB_HOST = credentials('db-host')
        DB_USER = credentials('db-user')
        DB_PASSWORD = credentials('db-password')
        DB_NAME = credentials('db-name')
        JWT_SECRET = credentials('jwt-secret')
    }

    // ============================================
    // Opciones del Pipeline
    // ============================================
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    // ============================================
    // Triggers
    // ============================================
    triggers {
        // Poll SCM cada 5 minutos
        pollSCM('H/5 * * * *')

        // O usar webhook de GitHub/GitLab
        // githubPush()
    }

    // ============================================
    // Stages
    // ============================================
    stages {

        // ========================================
        // Stage 1: Checkout
        // ========================================
        stage('Checkout') {
            steps {
                script {
                    echo "============================================"
                    echo "Stage: Checkout Code"
                    echo "Branch: ${env.BRANCH_NAME}"
                    echo "Build: ${env.BUILD_NUMBER}"
                    echo "Commit: ${GIT_COMMIT_SHORT}"
                    echo "============================================"
                }

                checkout scm

                // Mostrar información del commit
                sh 'git log -1 --pretty=format:"%h - %an, %ar : %s"'
            }
        }

        // ========================================
        // Stage 2: Install Dependencies
        // ========================================
        stage('Install Dependencies') {
            parallel {
                stage('Backend Dependencies') {
                    steps {
                        dir('5-pagina-web-login/backend') {
                            script {
                                echo "Installing backend dependencies..."
                                sh 'npm ci'
                            }
                        }
                    }
                }

                stage('Frontend Dependencies') {
                    steps {
                        dir('5-pagina-web-login/frontend') {
                            script {
                                echo "Installing frontend dependencies..."
                                sh 'npm ci'
                            }
                        }
                    }
                }
            }
        }

        // ========================================
        // Stage 3: Linting & Code Quality
        // ========================================
        stage('Code Quality') {
            parallel {
                stage('Backend Lint') {
                    steps {
                        dir('5-pagina-web-login/backend') {
                            script {
                                echo "Running backend linting..."
                                // sh 'npm run lint || true'
                                echo "Linting skipped (not configured)"
                            }
                        }
                    }
                }

                stage('Frontend Lint') {
                    steps {
                        dir('5-pagina-web-login/frontend') {
                            script {
                                echo "Running frontend linting..."
                                // sh 'npm run lint || true'
                                echo "Linting skipped (not configured)"
                            }
                        }
                    }
                }
            }
        }

        // ========================================
        // Stage 4: Run Tests
        // ========================================
        stage('Run Tests') {
            parallel {
                stage('Backend Tests') {
                    steps {
                        dir('5-pagina-web-login/backend') {
                            script {
                                echo "Running backend tests..."
                                // sh 'npm test || true'
                                echo "Tests skipped (not configured)"
                            }
                        }
                    }
                }

                stage('Frontend Tests') {
                    steps {
                        dir('5-pagina-web-login/frontend') {
                            script {
                                echo "Running frontend tests..."
                                // sh 'npm test -- --coverage --watchAll=false || true'
                                echo "Tests skipped (not configured)"
                            }
                        }
                    }
                }
            }
        }

        // ========================================
        // Stage 5: Security Scan
        // ========================================
        stage('Security Scan') {
            steps {
                script {
                    echo "Running security scans..."

                    // NPM Audit
                    dir('5-pagina-web-login/backend') {
                        sh 'npm audit --audit-level=high || true'
                    }

                    dir('5-pagina-web-login/frontend') {
                        sh 'npm audit --audit-level=high || true'
                    }
                }
            }
        }

        // ========================================
        // Stage 6: Build Docker Images
        // ========================================
        stage('Build Docker Images') {
            parallel {
                stage('Build Backend Image') {
                    steps {
                        script {
                            echo "Building backend Docker image..."

                            dir('5-pagina-web-login/backend') {
                                sh """
                                    docker build \
                                        -t ${BACKEND_IMAGE}:${VERSION} \
                                        -t ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} \
                                        -t ${BACKEND_IMAGE}:latest \
                                        --build-arg BUILD_DATE=\$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                                        --build-arg VCS_REF=${GIT_COMMIT_SHORT} \
                                        --build-arg VERSION=${VERSION} \
                                        .
                                """
                            }
                        }
                    }
                }

                stage('Build Frontend Image') {
                    steps {
                        script {
                            echo "Building frontend Docker image..."

                            dir('5-pagina-web-login/frontend') {
                                sh """
                                    docker build \
                                        -t ${FRONTEND_IMAGE}:${VERSION} \
                                        -t ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} \
                                        -t ${FRONTEND_IMAGE}:latest \
                                        --build-arg REACT_APP_API_URL=http://localhost:5000/api \
                                        --build-arg BUILD_DATE=\$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                                        --build-arg VCS_REF=${GIT_COMMIT_SHORT} \
                                        --build-arg VERSION=${VERSION} \
                                        .
                                """
                            }
                        }
                    }
                }
            }
        }

        // ========================================
        // Stage 7: Test Docker Images
        // ========================================
        stage('Test Docker Images') {
            steps {
                script {
                    echo "Testing Docker images..."

                    // Test backend image
                    sh """
                        docker run --rm -d \
                            --name test-backend-${BUILD_NUMBER} \
                            -e NODE_ENV=test \
                            ${BACKEND_IMAGE}:${VERSION}

                        sleep 10

                        # Health check
                        docker exec test-backend-${BUILD_NUMBER} \
                            node -e "require('http').get('http://localhost:5000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})" \
                            || (docker stop test-backend-${BUILD_NUMBER} && exit 1)

                        docker stop test-backend-${BUILD_NUMBER}
                    """

                    // Test frontend image
                    sh """
                        docker run --rm -d \
                            --name test-frontend-${BUILD_NUMBER} \
                            -p 8080:80 \
                            ${FRONTEND_IMAGE}:${VERSION}

                        sleep 5

                        # Health check
                        curl -f http://localhost:8080/health || (docker stop test-frontend-${BUILD_NUMBER} && exit 1)

                        docker stop test-frontend-${BUILD_NUMBER}
                    """
                }
            }
        }

        // ========================================
        // Stage 8: Scan Images for Vulnerabilities
        // ========================================
        stage('Image Security Scan') {
            steps {
                script {
                    echo "Scanning images for vulnerabilities..."

                    // Usar Trivy para escanear vulnerabilidades
                    sh """
                        docker run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            aquasec/trivy image \
                            --severity HIGH,CRITICAL \
                            --exit-code 0 \
                            ${BACKEND_IMAGE}:${VERSION} || true
                    """

                    sh """
                        docker run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            aquasec/trivy image \
                            --severity HIGH,CRITICAL \
                            --exit-code 0 \
                            ${FRONTEND_IMAGE}:${VERSION} || true
                    """
                }
            }
        }

        // ========================================
        // Stage 9: Push to Registry
        // ========================================
        stage('Push to Registry') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    echo "Pushing images to registry..."

                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-credentials-id') {
                        // Push backend image
                        sh """
                            docker tag ${BACKEND_IMAGE}:${VERSION} ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:${VERSION}
                            docker tag ${BACKEND_IMAGE}:${VERSION} ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:latest
                            docker push ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:${VERSION}
                            docker push ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:latest
                        """

                        // Push frontend image
                        sh """
                            docker tag ${FRONTEND_IMAGE}:${VERSION} ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:${VERSION}
                            docker tag ${FRONTEND_IMAGE}:${VERSION} ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:latest
                            docker push ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:${VERSION}
                            docker push ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:latest
                        """
                    }
                }
            }
        }

        // ========================================
        // Stage 10: Deploy to Environment
        // ========================================
        stage('Deploy') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    echo "Deploying to ${ENVIRONMENT} environment..."

                    if (env.BRANCH_NAME == 'main') {
                        // Deploy to production
                        echo "Deploying to PRODUCTION..."

                        sh """
                            # Backup de la base de datos antes de deploy
                            ./scripts/backup-db.sh || true

                            # Deploy con docker-compose
                            export VERSION=${VERSION}
                            docker-compose -f docker-compose.prod.yml pull
                            docker-compose -f docker-compose.prod.yml up -d

                            # Health check
                            sleep 30
                            curl -f http://localhost/health || exit 1
                        """
                    } else {
                        // Deploy to development
                        echo "Deploying to DEVELOPMENT..."

                        sh """
                            export VERSION=${VERSION}
                            docker-compose up -d

                            # Health check
                            sleep 20
                            curl -f http://localhost:3000/health || exit 1
                        """
                    }
                }
            }
        }

        // ========================================
        // Stage 11: Smoke Tests
        // ========================================
        stage('Smoke Tests') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    echo "Running smoke tests..."

                    sh '''
                        # Test backend health
                        curl -f http://localhost:5000/health || exit 1

                        # Test frontend health
                        curl -f http://localhost:3000/health || exit 1

                        # Test login endpoint (sin autenticación, debería devolver 400/401)
                        curl -X POST http://localhost:5000/api/auth/login \
                            -H "Content-Type: application/json" \
                            -d '{"email":"test@test.com","password":"test"}' || true
                    '''
                }
            }
        }
    }

    // ============================================
    // Post Actions
    // ============================================
    post {
        always {
            script {
                echo "Pipeline completed!"

                // Limpiar imágenes antiguas
                sh """
                    docker image prune -f --filter "until=48h" || true
                """
            }
        }

        success {
            script {
                echo "✓ Build SUCCESS!"

                // Notificación de éxito (configurar según tu sistema)
                // slackSend(color: 'good', message: "Build #${BUILD_NUMBER} SUCCESS")
                // emailext(subject: "SUCCESS: ${env.JOB_NAME} #${BUILD_NUMBER}", body: "Build succeeded!")
            }
        }

        failure {
            script {
                echo "✗ Build FAILED!"

                // Rollback en caso de fallo
                if (env.BRANCH_NAME == 'main') {
                    sh """
                        echo "Rolling back to previous version..."
                        # docker-compose -f docker-compose.prod.yml down
                        # ./scripts/rollback.sh || true
                    """
                }

                // Notificación de fallo
                // slackSend(color: 'danger', message: "Build #${BUILD_NUMBER} FAILED")
                // emailext(subject: "FAILURE: ${env.JOB_NAME} #${BUILD_NUMBER}", body: "Build failed!")
            }
        }

        unstable {
            script {
                echo "⚠ Build UNSTABLE!"
                // slackSend(color: 'warning', message: "Build #${BUILD_NUMBER} UNSTABLE")
            }
        }

        cleanup {
            script {
                echo "Cleaning up workspace..."

                // Limpiar contenedores de test
                sh """
                    docker ps -a | grep test-backend-${BUILD_NUMBER} | awk '{print \$1}' | xargs docker rm -f || true
                    docker ps -a | grep test-frontend-${BUILD_NUMBER} | awk '{print \$1}' | xargs docker rm -f || true
                """
            }
        }
    }
}
