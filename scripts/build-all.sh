#!/bin/bash

# ============================================
# Скрипт сборки всех микросервисов
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Сборка всех микросервисов            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"

# Функция для сборки сервиса
build_service() {
    local name=$1
    local path=$2
    local build_cmd=$3
    
    echo -e "\n${YELLOW}▶ Сборка ${name}...${NC}"
    cd "$PROJECT_ROOT/$path"
    
    if eval "$build_cmd"; then
        echo -e "${GREEN}✓ ${name} собран успешно${NC}"
        return 0
    else
        echo -e "${RED}✗ Ошибка сборки ${name}${NC}"
        return 1
    fi
}

# Параллельная сборка или последовательная
PARALLEL=${1:-false}

if [ "$PARALLEL" = "true" ] || [ "$PARALLEL" = "-p" ]; then
    echo -e "${YELLOW}Режим: параллельная сборка${NC}"
    
    # Параллельная сборка
    (cd "$PROJECT_ROOT/MicroServices/users-service" && ./gradlew clean build -x test --no-daemon) &
    (cd "$PROJECT_ROOT/MicroServices/accounts-service" && ./gradlew clean build -x test --no-daemon) &
    (cd "$PROJECT_ROOT/microService_bank/transfer_service" && ./gradlew clean build -x test --no-daemon) &
    (cd "$PROJECT_ROOT/microService_bank/notification_service" && ./gradlew clean build -x test --no-daemon) &
    (cd "$PROJECT_ROOT/bank" && ./gradlew :services:report:clean :services:report:build -x test --no-daemon) &
    (cd "$PROJECT_ROOT/bank" && ./gradlew :services:currency:clean :services:currency:build -x test --no-daemon) &
    (cd "$PROJECT_ROOT/micro_service" && ./gradlew :audit-service:clean :audit-service:build -x test --no-daemon) &
    (cd "$PROJECT_ROOT/micro_service" && ./gradlew :support-service:clean :support-service:build -x test --no-daemon) &
    
    wait
    
    echo -e "\n${GREEN}✓ Все сервисы собраны${NC}"
else
    echo -e "${YELLOW}Режим: последовательная сборка${NC}"
    echo -e "${YELLOW}(Используйте -p для параллельной сборки)${NC}"
    
    # Последовательная сборка
    build_service "users-service" "MicroServices/users-service" "./gradlew clean build -x test --no-daemon"
    build_service "accounts-service" "MicroServices/accounts-service" "./gradlew clean build -x test --no-daemon"
    build_service "transfer-service" "microService_bank/transfer_service" "./gradlew clean build -x test --no-daemon"
    build_service "notification-service" "microService_bank/notification_service" "./gradlew clean build -x test --no-daemon"
    build_service "report-service" "bank" "./gradlew :services:report:clean :services:report:build -x test --no-daemon"
    build_service "currency-service" "bank" "./gradlew :services:currency:clean :services:currency:build -x test --no-daemon"
    build_service "audit-service" "micro_service" "./gradlew :audit-service:clean :audit-service:build -x test --no-daemon"
    build_service "support-service" "micro_service" "./gradlew :support-service:clean :support-service:build -x test --no-daemon"
fi

echo -e "\n${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Сборка завершена успешно!            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"

