#!/bin/bash

# ============================================
# Скрипт локального развёртывания
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

# Параметры
ACTION=${1:-up}
SERVICE=${2:-}

show_help() {
    echo -e "${BLUE}Использование:${NC}"
    echo "  $0 [action] [service]"
    echo ""
    echo -e "${BLUE}Actions:${NC}"
    echo "  up        - Запустить все сервисы (по умолчанию)"
    echo "  down      - Остановить все сервисы"
    echo "  restart   - Перезапустить все сервисы"
    echo "  rebuild   - Пересобрать и запустить"
    echo "  logs      - Показать логи"
    echo "  status    - Показать статус контейнеров"
    echo "  clean     - Полная очистка (включая volumes)"
    echo ""
    echo -e "${BLUE}Service (опционально):${NC}"
    echo "  users-service, accounts-service, transfer-service,"
    echo "  notification-service, report-service, audit-service,"
    echo "  support-service, currency-service"
    echo ""
    echo -e "${BLUE}Примеры:${NC}"
    echo "  $0 up                    # Запустить всё"
    echo "  $0 restart users-service # Перезапустить users-service"
    echo "  $0 logs transfer-service # Логи transfer-service"
}

cd "$PROJECT_ROOT"

case "$ACTION" in
    up)
        echo -e "${BLUE}▶ Запуск сервисов...${NC}"
        if [ -n "$SERVICE" ]; then
            docker compose up -d "$SERVICE"
        else
            docker compose up -d
        fi
        echo -e "${GREEN}✓ Сервисы запущены${NC}"
        
        echo -e "\n${YELLOW}Ожидание готовности сервисов...${NC}"
        sleep 10
        
        "$SCRIPT_DIR/health-check.sh"
        ;;
        
    down)
        echo -e "${BLUE}▶ Остановка сервисов...${NC}"
        if [ -n "$SERVICE" ]; then
            docker compose stop "$SERVICE"
        else
            docker compose down
        fi
        echo -e "${GREEN}✓ Сервисы остановлены${NC}"
        ;;
        
    restart)
        echo -e "${BLUE}▶ Перезапуск сервисов...${NC}"
        if [ -n "$SERVICE" ]; then
            docker compose restart "$SERVICE"
        else
            docker compose restart
        fi
        echo -e "${GREEN}✓ Сервисы перезапущены${NC}"
        ;;
        
    rebuild)
        echo -e "${BLUE}▶ Пересборка и запуск...${NC}"
        if [ -n "$SERVICE" ]; then
            docker compose up -d --build "$SERVICE"
        else
            docker compose up -d --build
        fi
        echo -e "${GREEN}✓ Сервисы пересобраны и запущены${NC}"
        
        echo -e "\n${YELLOW}Ожидание готовности сервисов...${NC}"
        sleep 30
        
        "$SCRIPT_DIR/health-check.sh"
        ;;
        
    logs)
        if [ -n "$SERVICE" ]; then
            docker compose logs -f "$SERVICE"
        else
            docker compose logs -f
        fi
        ;;
        
    status)
        echo -e "${BLUE}▶ Статус контейнеров:${NC}\n"
        docker compose ps
        ;;
        
    clean)
        echo -e "${RED}▶ Полная очистка (включая данные)...${NC}"
        read -p "Вы уверены? Все данные будут удалены! (y/N) " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            docker compose down -v --remove-orphans
            docker system prune -f
            echo -e "${GREEN}✓ Очистка завершена${NC}"
        else
            echo -e "${YELLOW}Отменено${NC}"
        fi
        ;;
        
    help|--help|-h)
        show_help
        ;;
        
    *)
        echo -e "${RED}Неизвестное действие: $ACTION${NC}"
        show_help
        exit 1
        ;;
esac

