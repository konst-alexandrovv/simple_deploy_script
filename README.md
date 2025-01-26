# Deployment System Manual

## System structure
```
.
├─── src/
│ ├──── base/ #Basic Utilities
│ ├──── hosts/ # Host management
│ ├──── tasks/ # Tasks
│ ├─── rules/ # Rules
│ ├─── roles/ # Server roles.
│ ├──── vars/ # Variables
│ └───── plugins/ # Plugins
├─── hosts/
│ ├──── all # List of all hosts
│ ├──── prod/ # Production hosts
│ └──── stage/ # Staging hosts
├──── tasks/
│ ├──── nginx/ # Tasks nginx
│ ├──── postgres/ # Tasks postgres
│ └──── redis/ # Redis tasks
└──── deploy # Main script
```

## Main components

### 1. Hosts (hosts/)
- The hosts/all file contains a list of all hosts
- Regular expressions are supported:
```
web[1-3].prod # web1.prod, web2.prod, web3.prod
db[1-2].stage # db1.stage, db2.stage
```

### 2. Roles (roles/)
- Define the basic configuration of the server
- Each role is a directory with a set of scripts:
````bash
roles/web/
├─── base # Base packages
├──── security # Security settings
└─── monitoring # Monitoring
```

### 3. Tasks (tasks/)
- Atomic operations for services
- Executed sequentially:
````bash
tasks/nginx/
├─── install # Installation
├─── config # Configuration
└──── reload # Rebooting
```

### 4. Rules (rules/)
- Command templates with substitution:
```bash
# rules/scale
docker service scale %1=%2 # %1 is the service, %2 is the quantity
```

### 5. Variables (vars/)
- Environment variable files:
```bash
# vars/common
PORT=80
WORKERS=4
```

### 6. Plugins (plugins/)
- Hooks for deploy events:
```bash
plugins/notify/
├─── pre # Pre-deployment
└─── post # After deployment
```

## Usage Examples

1. basic deploy:
```bash
./deploy 'web.*' web nginx
```
- Selects all web servers
- Applies the 'web' role
- Performs nginx tasks

2. Scaling:
```bash
./deploy 'prod' scale webapp 5
```
- Selects all prod servers
- Applies the scale rule
- Scales the webapp to 5 replicas

3. Configuration with variables:
```bash
PORT=8080 ./deploy 'db.*' tasks/postgres/config
```
- Overrides the PORT variable
- Applies the postgres configuration

## Create components

1. New role:
```bash
mkdir -p roles/cache
echo “apt install -y redis” > roles/cache/base
```

2. New task:
````bash
mkdir -p tasks/redis
cat > tasks/redis/config << 'EOF'
maxmemory 2gb
maxmemory-policy allkeys-lru
EOF
```

3. new rule:
````bash
echo “systemctl %1 %2” > rules/service
# Usage: ./deploy 'web.*' service restart nginx
```

4. New plugin:
````bash
mkdir -p plugins/backup/pre
cat > plugins/backup/pre << 'EOF'
#!/bin/bash
tar -czf backup.tar.gz /etc/nginx
EOF
chmod +x plugins/backup/pre
```

## Tips for use

1. debugging:
```bash.
## View commands without executing
./deploy -n 'web.*' web nginx

# Detailed output
./deploy -v 'web.*' web nginx
```

2. Parallel execution:
````bash
# Restrict parallelism
PARALLEL=5 ./deploy 'web.*' web nginx
```

3. Conditional execution:
````bash
# Check before execution
./deploy 'web.*' check && ./deploy 'web.*' deploy
```

4. rollback:
````bash
# Rollback to previous version
./deploy 'web.*' rollback nginx
```

## Extend functionality

1. Adding a new host type:
```bash
echo “cache[1-2].prod” >> hosts/all
```

2. Creating a composite task:
````bash
cat tasks/web/* > tasks/full-stack/deploy
```

3. configuration templates:
```bash
# tasks/nginx/template
server {
    listen ${PORT};
    worker_connections ${WORKERS};
}
```

4. integration with monitoring:
```bash
# plugins/monitor/post
#!/bin/bash
curl -X POST http://prometheus/metrics -d “deploy_complete{service=\”$1\"}”

Review with Claude 3.5

# Руководство по системе деплоя

## Структура системы
```
.
├── src/
│   ├── base/           # Базовые утилиты
│   ├── hosts/          # Управление хостами
│   ├── tasks/          # Задачи
│   ├── rules/          # Правила
│   ├── roles/          # Роли серверов
│   ├── vars/           # Переменные
│   └── plugins/        # Плагины
├── hosts/
│   ├── all            # Список всех хостов
│   ├── prod/          # Хосты продакшена
│   └── stage/         # Хосты стейджинга
├── tasks/
│   ├── nginx/         # Задачи nginx
│   ├── postgres/      # Задачи postgres
│   └── redis/         # Задачи redis
└── deploy             # Основной скрипт
```

## Основные компоненты

### 1. Хосты (hosts/)
- Файл hosts/all содержит список всех хостов
- Поддерживаются регулярные выражения:
```
web[1-3].prod     # web1.prod, web2.prod, web3.prod
db[1-2].stage     # db1.stage, db2.stage
```

### 2. Роли (roles/)
- Определяют базовую конфигурацию сервера
- Каждая роль - директория с набором скриптов:
```bash
roles/web/
├── base          # Базовые пакеты
├── security      # Настройки безопасности
└── monitoring    # Мониторинг
```

### 3. Задачи (tasks/)
- Атомарные операции для сервисов
- Выполняются последовательно:
```bash
tasks/nginx/
├── install       # Установка
├── config        # Конфигурация
└── reload        # Перезагрузка
```

### 4. Правила (rules/)
- Шаблоны команд с подстановкой:
```bash
# rules/scale
docker service scale %1=%2  # %1 - сервис, %2 - количество
```

### 5. Переменные (vars/)
- Файлы с переменными окружения:
```bash
# vars/common
PORT=80
WORKERS=4
```

### 6. Плагины (plugins/)
- Хуки для событий деплоя:
```bash
plugins/notify/
├── pre           # До деплоя
└── post          # После деплоя
```

## Примеры использования

1. Базовый деплой:
```bash
./deploy 'web.*' web nginx
```
- Выбирает все web-серверы
- Применяет роль 'web'
- Выполняет задачи nginx

2. Масштабирование:
```bash
./deploy 'prod' scale webapp 5
```
- Выбирает все prod-серверы
- Применяет правило scale
- Масштабирует webapp до 5 реплик

3. Конфигурация с переменными:
```bash
PORT=8080 ./deploy 'db.*' tasks/postgres/config
```
- Переопределяет переменную PORT
- Применяет конфигурацию postgres

## Создание компонентов

1. Новая роль:
```bash
mkdir -p roles/cache
echo "apt install -y redis" > roles/cache/base
```

2. Новая задача:
```bash
mkdir -p tasks/redis
cat > tasks/redis/config << 'EOF'
maxmemory 2gb
maxmemory-policy allkeys-lru
EOF
```

3. Новое правило:
```bash
echo "systemctl %1 %2" > rules/service
# Использование: ./deploy 'web.*' service restart nginx
```

4. Новый плагин:
```bash
mkdir -p plugins/backup/pre
cat > plugins/backup/pre << 'EOF'
#!/bin/bash
tar -czf backup.tar.gz /etc/nginx
EOF
chmod +x plugins/backup/pre
```

## Советы по использованию

1. Отладка:
```bash
# Просмотр команд без выполнения
./deploy -n 'web.*' web nginx

# Подробный вывод
./deploy -v 'web.*' web nginx
```

2. Параллельное выполнение:
```bash
# Ограничение параллельности
PARALLEL=5 ./deploy 'web.*' web nginx
```

3. Условное выполнение:
```bash
# Проверка перед выполнением
./deploy 'web.*' check && ./deploy 'web.*' deploy
```

4. Откат:
```bash
# Откат к предыдущей версии
./deploy 'web.*' rollback nginx
```

## Расширение функциональности

1. Добавление нового типа хостов:
```bash
echo "cache[1-2].prod" >> hosts/all
```

2. Создание составной задачи:
```bash
cat tasks/web/* > tasks/full-stack/deploy
```

3. Шаблоны конфигураций:
```bash
# tasks/nginx/template
server {
    listen ${PORT};
    worker_connections ${WORKERS};
}
```

4. Интеграция с мониторингом:
```bash
# plugins/monitor/post
#!/bin/bash
curl -X POST http://prometheus/metrics -d "deploy_complete{service=\"$1\"}"

Review with Claude 3.5
