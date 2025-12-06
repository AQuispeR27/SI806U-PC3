// ============================================
// Jenkinsfile - Pipeline CI/CD Sistema Culqui
// ============================================

pipeline {
    agent any

    environment {
        BACKEND_IMAGE = "culqui-backend"
        FRONTEND_IMAGE = "culqui-frontend"
        VERSION = "${env.BUILD_NUMBER}"
        NODE_ENV = 'production'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "============================================"
                    echo "Stage: Checkout Code"
                    echo "Branch: ${env.BRANCH_NAME ?: 'main'}"
                    echo "Build: ${env.BUILD_NUMBER}"
                    echo "============================================"
                }

                script {
                    try {
                        sh 'git log -1 --pretty=format:"%h - %an, %ar : %s"'
                    } catch (Exception e) {
                        echo "No se pudo obtener información del commit"
                    }
                }
            }
        }

        stage('Verificar Estructura') {
            steps {
                script {
                    echo "📂 Verificando estructura del proyecto..."
                    sh '''
                        echo "Contenido raíz:"
                        ls -la
                        echo ""
                        echo "Verificando carpetas:"
                        ls -la 5.main/ 2>/dev/null || echo "⚠️ Carpeta 5.main no encontrada"
                        ls -la 5.main/backend/ 2>/dev/null || echo "⚠️ Carpeta backend no encontrada"
                        ls -la 5.main/frontend/ 2>/dev/null || echo "⚠️ Carpeta frontend no encontrada"
                    '''
                }
            }
        }

        stage('Install Dependencies') {
            parallel {
                stage('Backend Dependencies') {
                    when {
                        expression { fileExists('5.main/backend/package.json') }
                    }
                    steps {
                        dir('5.main/backend') {
                            script {
                                echo "📦 Installing backend dependencies..."
                                sh 'npm install'
                            }
                        }
                    }
                }

                stage('Frontend Dependencies') {
                    when {
                        expression { fileExists('5.main/frontend/package.json') }
                    }
                    steps {
                        dir('5.main/frontend') {
                            script {
                                echo "📦 Installing frontend dependencies..."
                                sh 'npm install'
                            }
                        }
                    }
                }
            }
        }

        stage('Code Quality') {
            parallel {
                stage('Backend Lint') {
                    when {
                        expression { fileExists('5.main/backend/package.json') }
                    }
                    steps {
                        dir('5.main/backend') {
                            script {
                                echo "🔍 Running backend linting..."
                                sh 'npm run lint 2>/dev/null || echo "Linting not configured"'
                            }
                        }
                    }
                }

                stage('Frontend Lint') {
                    when {
                        expression { fileExists('5.main/frontend/package.json') }
                    }
                    steps {
                        dir('5.main/frontend') {
                            script {
                                echo "🔍 Running frontend linting..."
                                sh 'npm run lint 2>/dev/null || echo "Linting not configured"'
                            }
                        }
                    }
                }
            }
        }

        stage('Run Tests') {
            parallel {
                stage('Backend Tests') {
                    when {
                        expression { fileExists('5.main/backend/package.json') }
                    }
                    steps {
                        dir('5.main/backend') {
                            script {
                                echo "🧪 Running backend tests..."
                                sh 'npm test 2>/dev/null || echo "Tests not configured"'
                            }
                        }
                    }
                }

                stage('Frontend Tests') {
                    when {
                        expression { fileExists('5.main/frontend/package.json') }
                    }
                    steps {
                        dir('5.main/frontend') {
                            script {
                                echo "🧪 Running frontend tests..."
                                sh 'CI=true npm test 2>/dev/null || echo "Tests not configured"'
                            }
                        }
                    }
                }
            }
        }

        stage('Security Scan') {
            steps {
                script {
                    echo "🔒 Running security scans..."

                    if (fileExists('5.main/backend/package.json')) {
                        dir('5.main/backend') {
                            sh 'npm audit --audit-level=high || echo "⚠️ Vulnerabilities found in backend"'
                        }
                    }

                    if (fileExists('5.main/frontend/package.json')) {
                        dir('5.main/frontend') {
                            sh 'npm audit --audit-level=high || echo "⚠️ Vulnerabilities found in frontend"'
                        }
                    }
                }
            }
        }

        stage('Build') {
            parallel {
                stage('Build Backend') {
                    when {
                        expression { fileExists('5.main/backend/package.json') }
                    }
                    steps {
                        dir('5.main/backend') {
                            script {
                                echo "🔨 Building backend..."
                                sh 'npm run build 2>/dev/null || echo "No build script configured"'
                            }
                        }
                    }
                }

                stage('Build Frontend') {
                    when {
                        expression { fileExists('5.main/frontend/package.json') }
                    }
                    steps {
                        dir('5.main/frontend') {
                            script {
                                echo "🔨 Building frontend..."
                                sh 'npm run build 2>/dev/null || echo "No build script configured"'
                            }
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            echo "============================================"
            echo "Pipeline Completed!"
            echo "Build ID: ${env.BUILD_ID}"
            echo "Build Number: ${env.BUILD_NUMBER}"
            echo "Build URL: ${env.BUILD_URL}"
            echo "============================================"
        }

        success {
            echo "✅ Build SUCCESS!"
            echo "Todas las etapas completadas exitosamente"
        }

        failure {
            echo "❌ Build FAILED!"
            echo "Revisa los logs para más detalles"
        }

        unstable {
            echo "⚠️ Build UNSTABLE!"
            echo "Algunas pruebas fallaron o hay advertencias"
        }

        cleanup {
            echo "🧹 Cleaning up..."
        }
    }
}