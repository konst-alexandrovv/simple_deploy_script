#!/bin/bash

# Installer prints messages in both Russian and English
msg() {
    echo "$1"
    echo "$2"
    echo
}

INSTALL_DIR=$(pwd)/deployer

# Create directory structure / Создаем структуру директорий
create_structure() {
    mkdir -p $INSTALL_DIR/{src/{base,hosts,tasks,rules,roles,vars,plugins},hosts/{prod,stage},tasks,rules,roles,vars/{common,prod,stage},plugins}
}

# Create base utilities / Создаем базовые утилиты
create_base_utils() {
    # executor
    cat > $INSTALL_DIR/src/base/executor << 'EOF'
#!/bin/bash
# Execute commands from input stream / Выполнение команд из входного потока
execute() {
    while read -r cmd; do
        [ -z "$cmd" ] && continue
        [ "${cmd:0:1}" = "#" ] && continue
        eval "$cmd"
    done
}
EOF

    # remote
    cat > $INSTALL_DIR/src/base/remote << 'EOF'
#!/bin/bash
# Execute commands on remote host / Выполнение команд на удаленном хосте
remote() {
    local host=$1
    shift
    ssh $host "$@"
}
EOF

    # stream
    cat > $INSTALL_DIR/src/base/stream << 'EOF'
#!/bin/bash
# Stream files between hosts / Потоковая передача файлов между хостами
stream() {
    local src=$1
    local dst=$2
    cat "$src" | ssh "$dst" "cat > $src"
}
EOF
}

# Create main components / Создаем основные компоненты
create_components() {
    # hosts filter / фильтр хостов
    cat > $INSTALL_DIR/src/hosts/filter << 'EOF'
#!/bin/bash
# Filter hosts by pattern / Фильтрация хостов по шаблону
host_filter() {
    local pattern=$1
    grep -E "$pattern" hosts/all
}
EOF

    # tasks composer / компоновщик задач
    cat > $INSTALL_DIR/src/tasks/compose << 'EOF'
#!/bin/bash
# Compose tasks from parts / Сборка задач из частей
compose() {
    local task=$1
    shift
    cat $(echo tasks/$task/* | sort)
}
EOF

    # rules applier / применение правил
    cat > $INSTALL_DIR/src/rules/apply << 'EOF'
#!/bin/bash
# Apply rules with substitution / Применение правил с подстановкой
apply_rules() {
    local file=$1
    shift
    sed "s|%[0-9]\+|$*|g" "rules/$file"
}
EOF

    # roles expander / расширение ролей
    cat > $INSTALL_DIR/src/roles/expand << 'EOF'
#!/bin/bash
# Expand role contents / Развертывание содержимого роли
expand_role() {
    local role=$1
    cat roles/$role/* 2>/dev/null
}
EOF

    # vars substitutor / подстановка переменных
    cat > $INSTALL_DIR/src/vars/substitute << 'EOF'
#!/bin/bash
# Substitute variables / Подстановка переменных
sub_vars() {
    local ctx=$1
    shift
    envsubst $(cat vars/$ctx | tr '\n' ' ')
}
EOF

    # plugin hook / хуки плагинов
    cat > $INSTALL_DIR/src/plugins/hook << 'EOF'
#!/bin/bash
# Execute plugin hooks / Выполнение хуков плагинов
hook() {
    local point=$1
    shift
    for plugin in plugins/*; do
        [ -x "$plugin/$point" ] && "$plugin/$point" "$@"
    done
}
EOF
}

# Create main deployment script / Создаем главный скрипт деплоя
create_main_script() {
    cat > $INSTALL_DIR/deploy << 'EOF'
#!/bin/bash

# Load base utilities / Загружаем базовые утилиты
for util in src/base/*; do
    source $util
done

deploy() {
    local verbose=false
    local dry_run=false
    local parallel=10

    # Parse options / Парсим опции
    while getopts "vnp:" opt; do
        case $opt in
            v) verbose=true ;;    # Verbose mode / Подробный режим
            n) dry_run=true ;;    # Dry run / Тестовый запуск
            p) parallel=$OPTARG ;; # Parallel tasks / Параллельные задачи
        esac
    done
    shift $((OPTIND-1))

    hook pre "$@"

    # Define hosts / Определяем хосты
    hosts=$(host_filter "$1")
    shift

    # Collect commands / Собираем команды
    {
        # Roles / Роли
        for role in "$@"; do
            [ -d "roles/$role" ] && expand_role "$role"
        done

        # Tasks / Задачи
        for task in "$@"; do
            [ -d "tasks/$task" ] && compose "$task"
        done

        # Rules / Правила
        for rule in "$@"; do
            [ -f "rules/$rule" ] && apply_rules "$rule" "$@"
        done
    } | sub_vars common | while read -r host; do
        if [ "$dry_run" = true ]; then
            echo "[DRY-RUN/ТЕСТ] Would execute on $host: $cmd"
        else
            if [ "$verbose" = true ]; then
                echo "[EXEC/ВЫПОЛНЕНИЕ] $host: $cmd"
            fi
            remote "$host" "$(cat)" &

            # Control parallelism / Контроль параллельности
            while [ $(jobs -r | wc -l) -ge $parallel ]; do
                sleep 1
            done
        fi
    done

    wait
    hook post "$@"
}

# Run with provided arguments / Запуск с переданными аргументами
deploy "$@"
EOF
    chmod +x $INSTALL_DIR/deploy
}

# Create examples / Создаем примеры
create_examples() {
    # Example host list / Пример списка хостов
    cat > $INSTALL_DIR/hosts/all << 'EOF'
# Production servers / Продакшен серверы
web1.prod
web2.prod
db1.prod

# Staging servers / Тестовые серверы
web1.stage
db1.stage
EOF

    # Example role / Пример роли
    mkdir -p $INSTALL_DIR/roles/web
    cat > $INSTALL_DIR/roles/web/base << 'EOF'
# Basic web server setup / Базовая настройка веб-сервера
apt update
apt install -y nginx redis
EOF

    # Example task / Пример задачи
    mkdir -p $INSTALL_DIR/tasks/nginx
    cat > $INSTALL_DIR/tasks/nginx/config << 'EOF'
# Nginx configuration / Конфигурация Nginx
cat > /etc/nginx/nginx.conf << 'EEOF'
worker_processes auto;
events {
    worker_connections 1024;
}
http {
    include mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;
    server {
        listen ${PORT};
        server_name localhost;
        location / {
            root /var/www/html;
            index index.html;
        }
    }
}
EEOF
EOF

    # Example rule / Пример правила
    cat > $INSTALL_DIR/rules/scale << 'EOF'
# Scale service / Масштабирование сервиса
docker service scale %1=%2
EOF

    # Example variables / Пример переменных
    cat > $INSTALL_DIR/vars/common << 'EOF'
# Common variables / Общие переменные
PORT=80
WORKERS=4
EOF

    # Example plugin / Пример плагина
    mkdir -p $INSTALL_DIR/plugins/notify
    cat > $INSTALL_DIR/plugins/notify/post << 'EOF'
#!/bin/bash
# Deployment notification / Уведомление о деплое
echo "[$(date)] Deploy complete for / Деплой завершен для: $*" >> /var/log/deploy.log
EOF
    chmod +x $INSTALL_DIR/plugins/notify/post
}

# Main installation process / Основной процесс установки
install() {
    msg "Установка системы деплоя в $INSTALL_DIR" \
        "Installing deployment system to $INSTALL_DIR"

    create_structure
    create_base_utils
    create_components
    create_main_script
    create_examples

    msg "Установка завершена" \
        "Installation complete"
    msg "Для использования:" \
        "To use:"
    msg "cd $INSTALL_DIR" \
        "cd $INSTALL_DIR"
    msg "./deploy 'web.*' web nginx" \
        "./deploy 'web.*' web nginx"
}

# Run installation / Запускаем установку
install
