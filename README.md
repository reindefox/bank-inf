# Bank Microservices Platform

Микросервисная архитектура банковской системы с интеграцией через RabbitMQ.

## 🚀 Быстрый старт

### Запуск всей системы

```bash
docker compose up --build
```

Это поднимет все 8 микросервисов, RabbitMQ и необходимые базы данных.

### Остановка системы

```bash
docker compose down
```

Для удаления volumes (данные БД):

```bash
docker compose down -v
```

## 📋 Сервисы и порты

| Сервис | Порт | Описание |
|--------|------|----------|
| **RabbitMQ Management** | 15672 | Веб-интерфейс RabbitMQ (guest/guest) |
| **RabbitMQ AMQP** | 5672 | AMQP протокол |
| **users-service** | 8081 | Управление пользователями (регистрация, авторизация) |
| **accounts-service** | 8082 | Управление счетами и картами |
| **transfer-service** | 8080 | Переводы между счетами |
| **notification-service** | 8083 | Уведомления |
| **report-service** | 8084 | Отчётность и аналитика |
| **audit-service** | 8085 | Аудит всех бизнес-событий |
| **support-service** | 8086 | Служба поддержки |
| **currency-service** | 8087 | Курсы валют |

## 🔄 Архитектура событий (RabbitMQ)

### Exchange
- **bank.events** (topic) — общий обменник для всех бизнес-событий

### События и routing keys

| Сервис | Публикует | Подписывается |
|--------|-----------|---------------|
| users-service | `user.registered` | — |
| accounts-service | `account.opened`, `card.issued`, `card.deleted` | `user.registered` |
| transfer-service | `transfer.completed`, `transfer.failed`, `transfer.created` | — |
| notification-service | — | `transfer.completed`, `transfer.failed`, `user.registered` |
| report-service | — | `transfer.completed`, `account.opened` |
| audit-service | — | `#.created`, `#.completed`, `#.failed`, `#.registered`, `#.opened`, `#.issued`, `#.deleted`, `#.updated` |
| support-service | `support.ticket.created` | — |
| currency-service | `currency.rate.updated` (опционально) | — |

## 🧪 Сквозной сценарий (End-to-End)

### 1. Регистрация пользователя

```bash
curl -X POST http://localhost:8081/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "fullName": "Test User"
  }'
```

**Ожидаемый результат:**
- Пользователь создан в `users-service`
- Событие `user.registered` отправлено в RabbitMQ
- `accounts-service` получил событие (лог)
- `notification-service` создал приветственное уведомление
- `audit-service` записал событие в БД

### 2. Авторизация

```bash
curl -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

Сохраните `access_token` из ответа.

### 3. Создание счёта

```bash
curl -X POST http://localhost:8082/api/accounts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"currency": "USD"}'
```

**Ожидаемый результат:**
- Счёт создан
- Событие `account.opened` отправлено
- `report-service` получил событие
- `audit-service` записал событие

### 4. Создание перевода

```bash
curl -X POST http://localhost:8080/api/transfers \
  -H "Content-Type: application/json" \
  -d '{
    "sourceAccountId": "account-uuid-1",
    "destinationAccountId": "account-uuid-2",
    "amount": 100.00,
    "currency": "USD"
  }'
```

**Ожидаемый результат:**
- Перевод создан в `transfer-service`
- Событие `transfer.completed` (или `transfer.failed`) отправлено
- `notification-service` создал уведомления для обоих участников
- `report-service` получил событие
- `audit-service` записал событие

### 5. Создание тикета поддержки

```bash
curl -X POST http://localhost:8086/api/support/requests \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "user-uuid",
    "subject": "Help needed",
    "message": "I need assistance with my account"
  }'
```

**Ожидаемый результат:**
- Тикет создан
- Событие `support.ticket.created` отправлено
- `audit-service` записал событие

### 6. Проверка аудита

```bash
curl http://localhost:8085/api/audit/messages
```

### 7. Конвертация валют

```bash
curl "http://localhost:8087/api/currency/convert?amount=100&from=USD&to=EUR"
```

## 📊 Мониторинг

### RabbitMQ Management UI
- URL: http://localhost:15672
- Логин: `guest`
- Пароль: `guest`

Здесь можно:
- Просматривать очереди и сообщения
- Мониторить обмены (exchanges)
- Отслеживать подключения сервисов

### Логи сервисов

```bash
# Все сервисы
docker compose logs -f

# Конкретный сервис
docker compose logs -f users-service
docker compose logs -f audit-service
```

## 🗄️ Базы данных

| Контейнер | Порт | База данных | Пользователь | Пароль |
|-----------|------|-------------|--------------|--------|
| db-main | 5432 | app | app | app |
| db-transfer | 5433 | transferdb | transfer_user | transfer_pass |
| db-notification | 5434 | notificationdb | notification_user | notification_pass |
| db-audit | 5435 | audit_db | audit_user | audit_pass |
| db-report | 5436 | reportdb | report_user | report_pass |

### Подключение к БД

```bash
# Пример подключения к db-main
psql -h localhost -p 5432 -U app -d app
```

## 🛠️ Разработка

### Локальный запуск отдельного сервиса

Каждый сервис можно запустить локально, указав переменные окружения:

```bash
# Пример для users-service
export DB_URL="jdbc:postgresql://localhost:5432/app"
export DB_USER="app"
export DB_PASSWORD="app"
export JWT_SECRET="secret"
export RABBIT_URL="amqp://guest:guest@localhost:5672/%2f"
export PORT=8081

cd MicroServices/users-service
./gradlew run
```

### Структура проекта

```
project/
├── docker-compose.yml          # Единый файл запуска
├── README.md                   # Документация
├── MicroServices/              
│   ├── users-service/          # Kotlin/Ktor
│   └── accounts-service/       # Kotlin/Ktor
├── microService_bank/          
│   ├── transfer_service/       # Java/Spring
│   └── notification_service/   # Java/Spring
├── micro_service/              
│   ├── audit-service/          # Kotlin/Ktor
│   └── support-service/        # Kotlin/Ktor
└── bank/                       
    └── services/
        ├── report/             # Kotlin/Spring
        └── currency/           # Kotlin/Spring
```

## 🔧 CI/CD

Проект настроен для автоматической сборки и развёртывания с использованием **Jenkins** и **GitHub Actions**.

### Jenkins (Локальный)

#### Требования

- Jenkins 2.400+ с установленными плагинами:
  - Pipeline
  - Docker Pipeline
  - Git
  - JUnit (для отчётов о тестах)
  - Blue Ocean (опционально, для красивого UI)

#### Установка Jenkins (macOS)

```bash
# Через Homebrew
brew install jenkins-lts

# Запуск
brew services start jenkins-lts

# Или напрямую
jenkins-lts
```

Jenkins будет доступен по адресу: http://localhost:8080

#### Установка Jenkins (Docker)

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

#### Настройка Pipeline

1. Откройте Jenkins: http://localhost:8080
2. Создайте новый Item → **Pipeline**
3. В разделе **Pipeline**:
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: путь к вашему репозиторию
   - Script Path: `Jenkinsfile`
4. Сохраните и запустите сборку

#### Параметры сборки Jenkins

| Параметр | Описание | Значения |
|----------|----------|----------|
| `DEPLOY_ENV` | Окружение развёртывания | dev, staging, prod |
| `RUN_TESTS` | Запускать тесты | true/false |
| `DEPLOY_ALL` | Развернуть все сервисы | true/false |
| `SERVICE_TO_DEPLOY` | Конкретный сервис | all, users-service, accounts-service, ... |

#### Этапы Pipeline

```
Checkout → Detect Changes → Build Services → Run Tests → Build Docker Images → Deploy → Health Check
```

1. **Checkout** — получение кода из репозитория
2. **Detect Changes** — определение изменённых сервисов
3. **Build Services** — параллельная сборка всех сервисов
4. **Run Tests** — параллельный запуск тестов
5. **Build Docker Images** — сборка Docker образов
6. **Deploy** — развёртывание через docker compose
7. **Health Check** — проверка здоровья всех сервисов

### GitHub Actions

#### Workflows

Проект содержит два workflow:

##### 1. CI Pipeline (`.github/workflows/ci.yml`)

Запускается автоматически при:
- Push в ветки `main`, `develop`, `feature/**`
- Pull Request в `main` или `develop`

**Особенности:**
- Определяет изменённые сервисы и собирает только их
- Параллельная сборка и тестирование
- Сборка Docker образов
- Интеграционные тесты на PR и main

##### 2. Deploy Pipeline (`.github/workflows/deploy.yml`)

Запускается:
- Автоматически при push в `main`
- Вручную через `workflow_dispatch`

**Параметры ручного запуска:**
- `environment` — staging или production
- `services` — список сервисов или "all"

#### Настройка GitHub Actions

1. Убедитесь, что репозиторий на GitHub
2. Перейдите в Settings → Environments
3. Создайте окружения: `staging` и `production`
4. Добавьте необходимые секреты (если нужны)

#### Использование GitHub Container Registry

Docker образы автоматически публикуются в GitHub Container Registry:

```bash
# Pull образа
docker pull ghcr.io/YOUR_USERNAME/YOUR_REPO/users-service:latest
```

### Ручной запуск CI/CD

#### Локальная сборка всех сервисов

```bash
# Сборка без тестов
./scripts/build-all.sh

# Или вручную
cd MicroServices/users-service && ./gradlew build -x test
cd MicroServices/accounts-service && ./gradlew build -x test
cd microService_bank/transfer_service && ./gradlew build -x test
cd microService_bank/notification_service && ./gradlew build -x test
cd bank && ./gradlew :services:report:build :services:currency:build -x test
cd micro_service && ./gradlew :audit-service:build :support-service:build -x test
```

#### Сборка Docker образов

```bash
# Все сервисы
docker compose build

# Конкретный сервис
docker compose build users-service
```

#### Проверка здоровья

```bash
# Все сервисы
curl -sf http://localhost:8081/health && echo "users-service OK"
curl -sf http://localhost:8082/health && echo "accounts-service OK"
curl -sf http://localhost:8080/actuator/health && echo "transfer-service OK"
curl -sf http://localhost:8083/actuator/health && echo "notification-service OK"
curl -sf http://localhost:8084/actuator/health && echo "report-service OK"
curl -sf http://localhost:8085/health && echo "audit-service OK"
curl -sf http://localhost:8086/health && echo "support-service OK"
curl -sf http://localhost:8087/actuator/health && echo "currency-service OK"
```

### Структура CI/CD файлов

```
project/
├── Jenkinsfile                      # Jenkins Pipeline
├── .github/
│   └── workflows/
│       ├── ci.yml                   # CI: сборка и тесты
│       └── deploy.yml               # CD: развёртывание
└── docker-compose.yml               # Конфигурация сервисов
```

---

## 📝 Техническое задание

<details>
<summary>Исходное ТЗ (развернуть)</summary>

### 1. Цель

**Создать единый локально запускаемый стенд (MVP)**, в котором все микросервисы из проекта поднимаются через один `docker-compose`, работают в общей сети и **взаимодействуют через брокер сообщений RabbitMQ** (асинхронное взаимодействие), при сохранении возможности прямых HTTP‑запросов.

### 2. Состав системы

- **users-service**: управление пользователями
- **accounts-service**: управление счетами
- **transfer_service**: переводы между счетами
- **notification_service**: отправка уведомлений
- **report**: сервис отчётности
- **audit-service**: аудит бизнес‑событий
- **support-service**: поддержка/обращения пользователей
- **currency**: сервис курсов валют

### 3. Критерии приёмки

- ✅ Все 8 сервисов и RabbitMQ успешно стартуют через один `docker compose up --build`
- ✅ Между сервисами проходят события через RabbitMQ в соответствии с описанной моделью
- ✅ Сквозной сценарий выполняется полностью, без фатальных ошибок в логах
- ✅ Всё необходимое для запуска и проверки описано в README

</details>