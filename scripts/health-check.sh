#!/bin/bash

# ============================================
# Скрипт проверки здоровья всех сервисов
# ============================================

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Проверка здоровья сервисов           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}\n"

# Массив сервисов для проверки
declare -A services=(
    ["users-service"]="http://localhost:8081/health"
    ["accounts-service"]="http://localhost:8082/health"
    ["transfer-service"]="http://localhost:8080/actuator/health"
    ["notification-service"]="http://localhost:8083/actuator/health"
    ["report-service"]="http://localhost:8084/actuator/health"
    ["audit-service"]="http://localhost:8085/health"
    ["support-service"]="http://localhost:8086/health"
    ["currency-service"]="http://localhost:8087/actuator/health"
)

# Инфраструктура
declare -A infra=(
    ["RabbitMQ"]="http://localhost:15672"
    ["Prometheus"]="http://localhost:9090"
    ["Grafana"]="http://localhost:3000"
)

healthy=0
unhealthy=0
total=0

echo -e "${YELLOW}▶ Инфраструктура:${NC}\n"

for name in "${!infra[@]}"; do
    url="${infra[$name]}"
    total=$((total + 1))
    
    if curl -sf "$url" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $name - ${GREEN}HEALTHY${NC}"
        healthy=$((healthy + 1))
    else
        echo -e "  ${RED}✗${NC} $name - ${RED}NOT AVAILABLE${NC}"
        unhealthy=$((unhealthy + 1))
    fi
done

echo -e "\n${YELLOW}▶ Микросервисы:${NC}\n"

for name in "${!services[@]}"; do
    url="${services[$name]}"
    total=$((total + 1))
    
    response=$(curl -sf "$url" 2>/dev/null)
    status=$?
    
    if [ $status -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} $name - ${GREEN}HEALTHY${NC}"
        healthy=$((healthy + 1))
    else
        echo -e "  ${RED}✗${NC} $name - ${RED}NOT HEALTHY${NC}"
        unhealthy=$((unhealthy + 1))
    fi
done

echo -e "\n${BLUE}══════════════════════════════════════════${NC}"
echo -e "${BLUE}Результат:${NC}"
echo -e "  Всего: $total"
echo -e "  ${GREEN}Здоровых: $healthy${NC}"
echo -e "  ${RED}Недоступных: $unhealthy${NC}"
echo -e "${BLUE}══════════════════════════════════════════${NC}"

if [ $unhealthy -eq 0 ]; then
    echo -e "\n${GREEN}✓ Все сервисы работают нормально!${NC}"
    exit 0
else
    echo -e "\n${YELLOW}⚠ Некоторые сервисы недоступны${NC}"
    exit 1
fi

