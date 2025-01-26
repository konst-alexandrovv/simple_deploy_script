# Deployment System

## System Structure

```
.
├── src/
│   ├── base/           # Basic Utilities
│   ├── hosts/          # Host Management
│   ├── tasks/          # Tasks
│   ├── rules/          # Rules
│   ├── roles/          # Server Roles
│   ├── vars/           # Variables
│   └── plugins/        # Plugins
├── hosts/
│   ├── all             # List of All Hosts
│   ├── prod/           # Production Hosts
│   └── stage/          # Staging Hosts
├── tasks/
│   ├── nginx/          # Nginx Tasks
│   ├── postgres/       # Postgres Tasks
│   └── redis/          # Redis Tasks
└── deploy              # Main Script
```

## Key Components

### 1. Hosts (`hosts/`)
- `hosts/all` contains a list of all hosts
- Supports regular expressions:
  ```
  web[1-3].prod  # web1.prod, web2.prod, web3.prod
  db[1-2].stage  # db1.stage, db2.stage
  ```

### 2. Roles (`roles/`)
- Define basic server configuration
- Each role is a directory with scripts:
  ```bash
  roles/web/
  ├── base        # Base packages
  ├── security    # Security settings
  └── monitoring  # Monitoring
  ```

### 3. Tasks (`tasks/`)
- Atomic service operations
- Executed sequentially:
  ```bash
  tasks/nginx/
  ├── install     # Installation
  ├── config      # Configuration
  └── reload      # Restarting
  ```

### 4. Rules (`rules/`)
- Command templates with substitution:
  ```bash
  # rules/scale
  docker service scale %1=%2  # %1 is service, %2 is quantity
  ```

### 5. Variables (`vars/`)
- Environment variable files:
  ```bash
  # vars/common
  PORT=80
  WORKERS=4
  ```

### 6. Plugins (`plugins/`)
- Deployment event hooks:
  ```bash
  plugins/notify/
  ├── pre         # Pre-deployment
  └── post        # Post-deployment
  ```

## Usage Examples

### Basic Deployment
```bash
./deploy 'web.*' web nginx
```
- Selects all web servers
- Applies 'web' role
- Performs nginx tasks

### Scaling
```bash
./deploy 'prod' scale webapp 5
```
- Selects all prod servers
- Applies scale rule
- Scales webapp to 5 replicas

### Configuration with Variables
```bash
PORT=8080 ./deploy 'db.*' tasks/postgres/config
```
- Overrides PORT variable
- Applies postgres configuration

## Creating Components

### New Role
```bash
mkdir -p roles/cache
echo "apt install -y redis" > roles/cache/base
```

### New Task
```bash
mkdir -p tasks/redis
cat > tasks/redis/config << 'EOF'
maxmemory 2gb
maxmemory-policy allkeys-lru
EOF
```

### New Rule
```bash
echo "systemctl %1 %2" > rules/service
# Usage: ./deploy 'web.*' service restart nginx
```

### New Plugin
```bash
mkdir -p plugins/backup/pre
cat > plugins/backup/pre << 'EOF'
#!/bin/bash
tar -czf backup.tar.gz /etc/nginx
EOF
chmod +x plugins/backup/pre
```

## Usage Tips

### Debugging
```bash
# View commands without executing
./deploy -n 'web.*' web nginx

# Detailed output
./deploy -v 'web.*' web nginx
```

### Parallel Execution
```bash
# Limit parallelism
PARALLEL=5 ./deploy 'web.*' web nginx
```

### Conditional Execution
```bash
# Check before execution
./deploy 'web.*' check && ./deploy 'web.*' deploy
```

### Rollback
```bash
# Rollback to previous version
./deploy 'web.*' rollback nginx
```

## Extending Functionality

### Add New Host Type
```bash
echo "cache[1-2].prod" >> hosts/all
```

### Create Composite Task
```bash
cat tasks/web/* > tasks/full-stack/deploy
```

### Configuration Templates
```bash
# tasks/nginx/template
server {
    listen ${PORT};
    worker_connections ${WORKERS};
}
```

### Monitoring Integration
```bash
# plugins/monitor/post
#!/bin/bash
curl -X POST http://prometheus/metrics -d "deploy_complete{service=\"$1\"}"
```

Review with Claude 3.5

# Система Деплоя

## Структура Системы

```
.
├── src/
│   ├── base/           # Базовые Утилиты
│   ├── hosts/          # Управление Хостами
│   ├── tasks/          # Задачи
│   ├── rules/          # Правила
│   ├── roles/          # Роли Серверов
│   ├── vars/           # Переменные
│   └── plugins/        # Плагины
├── hosts/
│   ├── all             # Список Всех Хостов
│   ├── prod/           # Хосты Продакшена
│   └── stage/          # Хосты Стейджинга
├── tasks/
│   ├── nginx/          # Задачи Nginx
│   ├── postgres/       # Задачи Postgres
│   └── redis/          # Задачи Redis
└── deploy              # Основной Скрипт
```

## Ключевые Компоненты

### 1. Хосты (`hosts/`)
- `hosts/all` содержит список всех хостов
- Поддерживает регулярные выражения:
  ```
  web[1-3].prod  # web1.prod, web2.prod, web3.prod
  db[1-2].stage  # db1.stage, db2.stage
  ```

### 2. Роли (`roles/`)
- Определяют базовую конфигурацию сервера
- Каждая роль - директория со скриптами:
  ```bash
  roles/web/
  ├── base        # Базовые пакеты
  ├── security    # Настройки безопасности
  └── monitoring  # Мониторинг
  ```

### 3. Задачи (`tasks/`)
- Атомарные операции для сервисов
- Выполняются последовательно:
  ```bash
  tasks/nginx/
  ├── install     # Установка
  ├── config      # Конфигурация
  └── reload      # Перезапуск
  ```

### 4. Правила (`rules/`)
- Шаблоны команд с подстановкой:
  ```bash
  # rules/scale
  docker service scale %1=%2  # %1 - сервис, %2 - количество
  ```

### 5. Переменные (`vars/`)
- Файлы переменных окружения:
  ```bash
  # vars/common
  PORT=80
  WORKERS=4
  ```

### 6. Плагины (`plugins/`)
- Хуки событий деплоя:
  ```bash
  plugins/notify/
  ├── pre         # До деплоя
  └── post        # После деплоя
  ```

## Примеры Использования

### Базовое Развертывание
```bash
./deploy 'web.*' web nginx
```
- Выбирает все веб-серверы
- Применяет роль 'web'
- Выполняет задачи nginx

### Масштабирование
```bash
./deploy 'prod' scale webapp 5
```
- Выбирает все prod-серверы
- Применяет правило масштабирования
- Масштабирует webapp до 5 реплик

### Конфигурация с Переменными
```bash
PORT=8080 ./deploy 'db.*' tasks/postgres/config
```
- Переопределяет переменную PORT
- Применяет конфигурацию postgres

## Создание Компонентов

### Новая Роль
```bash
mkdir -p roles/cache
echo "apt install -y redis" > roles/cache/base
```

### Новая Задача
```bash
mkdir -p tasks/redis
cat > tasks/redis/config << 'EOF'
maxmemory 2gb
maxmemory-policy allkeys-lru
EOF
```

### Новое Правило
```bash
echo "systemctl %1 %2" > rules/service
# Использование: ./deploy 'web.*' service restart nginx
```

### Новый Плагин
```bash
mkdir -p plugins/backup/pre
cat > plugins/backup/pre << 'EOF'
#!/bin/bash
tar -czf backup.tar.gz /etc/nginx
EOF
chmod +x plugins/backup/pre
```

## Советы по Использованию

### Отладка
```bash
# Просмотр команд без выполнения
./deploy -n 'web.*' web nginx

# Подробный вывод
./deploy -v 'web.*' web nginx
```

### Параллельное Выполнение
```bash
# Ограничение параллельности
PARALLEL=5 ./deploy 'web.*' web nginx
```

### Условное Выполнение
```bash
# Проверка перед выполнением
./deploy 'web.*' check && ./deploy 'web.*' deploy
```

### Откат
```bash
# Откат к предыдущей версии
./deploy 'web.*' rollback nginx
```

## Расширение Функциональности

### Добавление Нового Типа Хостов
```bash
echo "cache[1-2].prod" >> hosts/all
```

### Создание Составной Задачи
```bash
cat tasks/web/* > tasks/full-stack/deploy
```

### Шаблоны Конфигураций
```bash
# tasks/nginx/template
server {
    listen ${PORT};
    worker_connections ${WORKERS};
}
```

### Интеграция с Мониторингом
```bash
# plugins/monitor/post
#!/bin/bash
curl -X POST http://prometheus/metrics -d "deploy_complete{service=\"$1\"}"
```

Review with Claude 3.5
