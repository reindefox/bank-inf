pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'localhost:5000'  // Локальный Docker Registry (опционально)
        DOCKER_COMPOSE_FILE = 'docker-compose.yml'
        // Учётные данные для Docker Registry (если используется)
        // DOCKER_CREDENTIALS = credentials('docker-credentials')
    }

    options {
        // Сохраняем последние 10 сборок
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // Таймаут для всего pipeline
        timeout(time: 30, unit: 'MINUTES')
        // Timestamp в логах
        timestamps()
        // Не собирать одновременно несколько сборок
        disableConcurrentBuilds()
    }

    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['dev', 'staging', 'prod'],
            description: 'Окружение для развёртывания'
        )
        booleanParam(
            name: 'RUN_TESTS',
            defaultValue: true,
            description: 'Запускать тесты?'
        )
        booleanParam(
            name: 'DEPLOY_ALL',
            defaultValue: true,
            description: 'Развернуть все сервисы или только изменённые?'
        )
        choice(
            name: 'SERVICE_TO_DEPLOY',
            choices: ['all', 'users-service', 'accounts-service', 'transfer-service', 'notification-service', 'report-service', 'audit-service', 'support-service', 'currency-service'],
            description: 'Какой сервис развернуть (если не все)'
        )
    }

    stages {
        stage('Checkout') {
            steps {
                echo "📥 Получение исходного кода..."
                checkout scm
            }
        }

        stage('Detect Changes') {
            steps {
                script {
                    // Определяем, какие сервисы изменились
                    def changes = []
                    
                    if (params.DEPLOY_ALL || params.SERVICE_TO_DEPLOY == 'all') {
                        changes = ['users-service', 'accounts-service', 'transfer-service', 
                                   'notification-service', 'report-service', 'audit-service', 
                                   'support-service', 'currency-service']
                    } else {
                        changes = [params.SERVICE_TO_DEPLOY]
                    }
                    
                    env.SERVICES_TO_BUILD = changes.join(',')
                    echo "🔍 Сервисы для сборки: ${env.SERVICES_TO_BUILD}"
                }
            }
        }

        stage('Build Services') {
            parallel {
                stage('Build users-service') {
                    when {
                        expression { env.SERVICES_TO_BUILD.contains('users-service') }
                    }
                    steps {
                        dir('MicroServices/users-service') {
                            sh './gradlew clean build -x test --no-daemon'
                        }
                    }
                }
                
                stage('Build accounts-service') {
                    when {
                        expression { env.SERVICES_TO_BUILD.contains('accounts-service') }
                    }
                    steps {
                        dir('MicroServices/accounts-service') {
                            sh './gradlew clean build -x test --no-daemon'
                        }
                    }
                }
                
                stage('Build transfer-service') {
                    when {
                        expression { env.SERVICES_TO_BUILD.contains('transfer-service') }
                    }
                    steps {
                        dir('microService_bank/transfer_service') {
                            sh './gradlew clean build -x test --no-daemon'
                        }
                    }
                }
                
                stage('Build notification-service') {
                    when {
                        expression { env.SERVICES_TO_BUILD.contains('notification-service') }
                    }
                    steps {
                        dir('microService_bank/notification_service') {
                            sh './gradlew clean build -x test --no-daemon'
                        }
                    }
                }
                
                stage('Build report-service') {
                    when {
                        expression { env.SERVICES_TO_BUILD.contains('report-service') }
                    }
                    steps {
                        dir('bank') {
                            sh './gradlew :services:report:clean :services:report:build -x test --no-daemon'
                        }
                    }
                }
                
                stage('Build audit-service') {
                    when {
                        expression { env.SERVICES_TO_BUILD.contains('audit-service') }
                    }
                    steps {
                        dir('micro_service') {
                            sh './gradlew :audit-service:clean :audit-service:build -x test --no-daemon'
                        }
                    }
                }
                
                stage('Build support-service') {
                    when {
                        expression { env.SERVICES_TO_BUILD.contains('support-service') }
                    }
                    steps {
                        dir('micro_service') {
                            sh './gradlew :support-service:clean :support-service:build -x test --no-daemon'
                        }
                    }
                }
                
                stage('Build currency-service') {
                    when {
                        expression { env.SERVICES_TO_BUILD.contains('currency-service') }
                    }
                    steps {
                        dir('bank') {
                            sh './gradlew :services:currency:clean :services:currency:build -x test --no-daemon'
                        }
                    }
                }
            }
        }

        stage('Run Tests') {
            when {
                expression { params.RUN_TESTS }
            }
            parallel {
                stage('Test users-service') {
                    when {
                        expression { env.SERVICES_TO_BUILD.contains('users-service') }
                    }
                    steps {
                        dir('MicroServices/users-service') {
                            sh './gradlew test --no-daemon'
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'MicroServices/users-service/build/test-results/test/*.xml'
                        }
                    }
                }
                
                stage('Test accounts-service') {
                    when {
                        expression { env.SERVICES_TO_BUILD.contains('accounts-service') }
                    }
                    steps {
                        dir('MicroServices/accounts-service') {
                            sh './gradlew test --no-daemon'
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'MicroServices/accounts-service/build/test-results/test/*.xml'
                        }
                    }
                }
                
                stage('Test transfer-service') {
                    when {
                        expression { env.SERVICES_TO_BUILD.contains('transfer-service') }
                    }
                    steps {
                        dir('microService_bank/transfer_service') {
                            sh './gradlew test --no-daemon'
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'microService_bank/transfer_service/build/test-results/test/*.xml'
                        }
                    }
                }
                
                stage('Test notification-service') {
                    when {
                        expression { env.SERVICES_TO_BUILD.contains('notification-service') }
                    }
                    steps {
                        dir('microService_bank/notification_service') {
                            sh './gradlew test --no-daemon'
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'microService_bank/notification_service/build/test-results/test/*.xml'
                        }
                    }
                }
                
                stage('Test report-service') {
                    when {
                        expression { env.SERVICES_TO_BUILD.contains('report-service') }
                    }
                    steps {
                        dir('bank') {
                            sh './gradlew :services:report:test --no-daemon'
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'bank/services/report/build/test-results/test/*.xml'
                        }
                    }
                }
                
                stage('Test audit-service') {
                    when {
                        expression { env.SERVICES_TO_BUILD.contains('audit-service') }
                    }
                    steps {
                        dir('micro_service') {
                            sh './gradlew :audit-service:test --no-daemon'
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'micro_service/audit-service/build/test-results/test/*.xml'
                        }
                    }
                }
                
                stage('Test support-service') {
                    when {
                        expression { env.SERVICES_TO_BUILD.contains('support-service') }
                    }
                    steps {
                        dir('micro_service') {
                            sh './gradlew :support-service:test --no-daemon'
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'micro_service/support-service/build/test-results/test/*.xml'
                        }
                    }
                }
                
                stage('Test currency-service') {
                    when {
                        expression { env.SERVICES_TO_BUILD.contains('currency-service') }
                    }
                    steps {
                        dir('bank') {
                            sh './gradlew :services:currency:test --no-daemon'
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'bank/services/currency/build/test-results/test/*.xml'
                        }
                    }
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    echo "🐳 Сборка Docker образов..."
                    
                    def services = env.SERVICES_TO_BUILD.split(',')
                    
                    services.each { service ->
                        switch(service.trim()) {
                            case 'users-service':
                                sh 'docker build -t users-service:latest ./MicroServices/users-service'
                                break
                            case 'accounts-service':
                                sh 'docker build -t accounts-service:latest ./MicroServices/accounts-service'
                                break
                            case 'transfer-service':
                                sh 'docker build -t transfer-service:latest ./microService_bank/transfer_service'
                                break
                            case 'notification-service':
                                sh 'docker build -t notification-service:latest ./microService_bank/notification_service'
                                break
                            case 'report-service':
                                sh 'docker build -t report-service:latest -f ./bank/services/report/Dockerfile ./bank'
                                break
                            case 'audit-service':
                                sh 'docker build -t audit-service:latest -f ./micro_service/audit-service/Dockerfile ./micro_service'
                                break
                            case 'support-service':
                                sh 'docker build -t support-service:latest -f ./micro_service/support-service/Dockerfile ./micro_service'
                                break
                            case 'currency-service':
                                sh 'docker build -t currency-service:latest -f ./bank/services/currency/Dockerfile ./bank'
                                break
                        }
                    }
                }
            }
        }

        stage('Deploy') {
            when {
                expression { params.DEPLOY_ENV == 'dev' || params.DEPLOY_ENV == 'staging' }
            }
            steps {
                script {
                    echo "🚀 Развёртывание в окружение: ${params.DEPLOY_ENV}"
                    
                    // Останавливаем существующие контейнеры
                    sh 'docker compose down || true'
                    
                    // Запускаем новые
                    sh 'docker compose up -d --build'
                    
                    // Ждём, пока сервисы станут доступны
                    echo "⏳ Ожидание готовности сервисов..."
                    sleep(time: 30, unit: 'SECONDS')
                }
            }
        }

        stage('Health Check') {
            when {
                expression { params.DEPLOY_ENV == 'dev' || params.DEPLOY_ENV == 'staging' }
            }
            steps {
                script {
                    echo "🏥 Проверка здоровья сервисов..."
                    
                    def healthChecks = [
                        'users-service': 'http://localhost:8081/health',
                        'accounts-service': 'http://localhost:8082/health',
                        'transfer-service': 'http://localhost:8080/actuator/health',
                        'notification-service': 'http://localhost:8083/actuator/health',
                        'report-service': 'http://localhost:8084/actuator/health',
                        'audit-service': 'http://localhost:8085/health',
                        'support-service': 'http://localhost:8086/health',
                        'currency-service': 'http://localhost:8087/actuator/health'
                    ]
                    
                    def failedServices = []
                    
                    healthChecks.each { service, url ->
                        try {
                            def response = sh(script: "curl -sf ${url} || echo 'FAILED'", returnStdout: true).trim()
                            if (response == 'FAILED') {
                                failedServices.add(service)
                                echo "❌ ${service} - NOT HEALTHY"
                            } else {
                                echo "✅ ${service} - HEALTHY"
                            }
                        } catch (Exception e) {
                            failedServices.add(service)
                            echo "❌ ${service} - NOT HEALTHY (${e.message})"
                        }
                    }
                    
                    if (failedServices.size() > 0) {
                        echo "⚠️ Некоторые сервисы не прошли проверку здоровья: ${failedServices.join(', ')}"
                        // Не фейлим сборку, только предупреждаем
                    }
                }
            }
        }

        stage('Deploy to Production') {
            when {
                allOf {
                    expression { params.DEPLOY_ENV == 'prod' }
                    branch 'main'
                }
            }
            steps {
                // Требуем ручное подтверждение для продакшена
                input message: '🚨 Подтвердите развёртывание в PRODUCTION', ok: 'Deploy'
                
                script {
                    echo "🚀 Развёртывание в PRODUCTION..."
                    // Здесь можно добавить логику для продакшен-деплоя
                    // Например, деплой на удалённый сервер через SSH
                    sh 'docker compose -f docker-compose.yml up -d --build'
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline выполнен успешно!'
            // Можно добавить уведомление в Slack/Telegram
            // slackSend(color: 'good', message: "Build ${BUILD_NUMBER} успешно завершён")
        }
        failure {
            echo '❌ Pipeline завершился с ошибкой!'
            // slackSend(color: 'danger', message: "Build ${BUILD_NUMBER} завершился с ошибкой")
        }
        always {
            // Очистка workspace (опционально)
            // cleanWs()
            echo "📋 Сборка #${BUILD_NUMBER} завершена. Статус: ${currentBuild.currentResult}"
        }
    }
}

