# Мониторинг микросервисов (Prometheus + Grafana)

## Структура

```
monitoring/
├── prometheus/
│   └── prometheus.yml      # Конфигурация Prometheus
└── grafana/
    └── provisioning/
        ├── datasources/
        │   └── datasources.yml     # Автоконфигурация источника данных
        └── dashboards/
            ├── dashboards.yml      # Провайдер дашбордов
            └── microservices-status.json  # Готовый дашборд
```

## Запуск

```bash
# Запустить все сервисы вместе с мониторингом
docker-compose up -d

# Или только мониторинг (если сервисы уже запущены)
docker-compose up -d prometheus grafana blackbox-exporter
```

## Доступ

| Сервис | URL | Учётные данные |
|--------|-----|----------------|
| **Grafana** | http://localhost:3000 | admin / admin |
| **Prometheus** | http://localhost:9090 | - |
| **Blackbox Exporter** | http://localhost:9115 | - |

## Как это работает

### Prometheus
- Собирает метрики каждые 15 секунд
- Для Spring Boot сервисов: `/actuator/prometheus`
- Для Ktor сервисов: `/health`

### Blackbox Exporter
- Проверяет доступность сервисов через HTTP probe
- Метрика `probe_success = 1` означает, что сервис доступен

### Grafana
- Автоматически подключается к Prometheus
- Готовый дашборд "Microservices Status" показывает:
  - Статус каждого сервиса (UP/DOWN)
  - Время отклика
  - История доступности

## Мониторируемые сервисы

| Сервис | Порт | Тип | Endpoint |
|--------|------|-----|----------|
| users-service | 8081 | Ktor | /health |
| accounts-service | 8082 | Ktor | /health |
| transfer-service | 8080 | Spring Boot | /actuator/health |
| notification-service | 8083 | Spring Boot | /actuator/health |
| report-service | 8084 | Spring Boot | /actuator/health |
| audit-service | 8085 | Ktor | /health |
| support-service | 8086 | Ktor | /health |
| currency-service | 8087 | Spring Boot | /actuator/health |

## Полезные запросы PromQL

```promql
# Проверить доступность сервиса
probe_success{job="blackbox-http"}

# Время отклика сервисов
probe_duration_seconds

# Количество UP сервисов
count(probe_success == 1)

# Процент доступности за последний час
avg_over_time(probe_success[1h]) * 100
```

## Добавление алертов (опционально)

Для настройки алертов добавьте в `prometheus.yml`:

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - 'alerts.yml'
```

И создайте `alerts.yml`:

```yaml
groups:
  - name: microservices
    rules:
      - alert: ServiceDown
        expr: probe_success == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.instance }} is down"
```

