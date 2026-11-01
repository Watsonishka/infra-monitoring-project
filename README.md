# infra-monitoring-project

Система мониторинга доступности API, анализа логов и контейнеризированная среда для развёртывания echo-сервиса.

Проект включает:
- файл `http_capture.pcapng` с дампом трафика из программы Wireshark;
- Bash-скрипт `check_api.sh` для мониторинга API;
- Bash-скрипт `analyze_logs.sh` для анализа логов;
- файл `docker-compose.yml` с образом `hashicorp/http-echo` и образом `nginx:alpine`;
- CI-пайплайн GitHub Actions для автоматической проверки синтаксиса Bash-скриптов, тестирования работы `check_api.sh` и прогона `analyze_logs.sh`;
- описание процесса безопасной передачи файлов проекта на удалённый сервер (п.4 README).

Подробный отчёт о работе представлен отдельным файлом в формате Word.

## 1. Структура репозитория

```
infra-monitoring-project/
├── .github/
│   └── workflows/
│       └── ci.yml            # CI-пайплайн GitHub Actions
├── traffic/
│   └── http_capture.pcapng   # дамп HTTP/HTTPS-трафика (Wireshark)
├── analyze_logs.sh           # генерация и анализ access.log
├── check_api.sh              # мониторинг API
├── docker-compose.yml        # стек Docker Compose: http-echo + nginx
├── .gitattributes            
├── .gitignore               
└── README.md
```

## 2. Программное обеспечение

- Ubuntu (VirtualBox)
- Git / GitHub
- Docker и Docker Compose
- Wireshark

## 3. Запуск

Клонирование репозитория:

```bash
git clone git@github.com:Watsonishka/infra-monitoring-project.git
cd infra-monitoring-project
chmod +x check_api.sh analyze_logs.sh
```

Проверка доступности API (код возврата 0 — API доступен, 1 — недоступен или ошибка):

```bash
./check_api.sh https://httpbin.org/status/200
```

Генерация и анализ логов (общее число запросов, топ-3 IP, количество ответов 4xx и 5xx):

```bash
./analyze_logs.sh
```

Запуск Docker-стека (nginx на порту 80 проксирует запросы в http-echo на порту 8080):

```bash
docker-compose up -d
docker-compose ps
curl http://localhost:80
docker-compose down
```

CI-пайплайн запускается автоматически при создании Pull Request в `main` и при push в `feature/monitoring`.

## 4. SSH и SCP

### 4.1. Генерация SSH-ключей

На локальной машине создаётся пара ключей: приватный, который остаётся только у владельца, и публичный, который передаётся на сервер.

`ssh-keygen -t ed25519 -C "your_email@example.com"`, где:
- `-t ed25519` — современный и надёжный алгоритм;
- `-C` — комментарий для идентификации ключа.

По умолчанию создаются файлы:
- `~/.ssh/id_ed25519` — приватный ключ, никому не передаётся и не коммитится в репозиторий;
- `~/.ssh/id_ed25519.pub` — публичный ключ.

Если требуется классический алгоритм RSA (например, для старого оборудования):
`ssh-keygen -t rsa -b 4096 -C "your_email@example.com"`

Вывести публичный ключ на экран (чтобы скопировать):
`cat ~/.ssh/id_ed25519.pub`

Сменить пароль для существующего ключа:
`ssh-keygen -p -f ~/.ssh/id_ed25519`

Удалить старый отпечаток сервера из `known_hosts`:
`ssh-keygen -R <адрес_сервера>`

### 4.2. Копирование публичного ключа

При первом выполнении команды копирования система попросит ввести пароль пользователя на удалённом сервере.

Базовое копирование (ключ по умолчанию из `~/.ssh/` будет отправлен на сервер):
`ssh-copy-id username@192.168.1.50`

Копирование конкретного файла ключа (если у вас несколько ключей или используется `.pub`-файл с другим именем):
`ssh-copy-id -i ~/.ssh/id_ed25519.pub username@192.168.1.50`

Подключение через нестандартный порт (например, порт 2222):
`ssh-copy-id -p 2222 username@192.168.1.50`

Через флаг `-o` (позволяет передать произвольный параметр конфигурации SSH напрямую в командной строке):
`ssh-copy-id -o "Port 2222" username@192.168.1.50`

### 4.3. Передача архива проекта через scp или tar + ssh

#### Вариант 1: tar + ssh

Этот метод создаёт архив, сжимает его, передаёт по SSH и сразу распаковывает на целевом сервере. Никаких лишних файлов на диске не остаётся.

`tar -czf - -C /путь/к infra-monitoring-project | ssh user@remote_ip "tar -xzf - -C /куда/распаковать"`, где:
- `tar -czf -` — архивирует (`c`) папку проекта, сжимает через gzip (`z`) и направляет поток в stdout (`-`);
- `-C /путь/к` — перед архивацией перейти в родительскую папку, чтобы в архив попала только папка проекта, без полного пути;
- `ssh ...` — передаёт этот поток данных через безопасное SSH-соединение;
- `tar -xzf - -C ...` — принимает поток из stdin (`-`), разжимает (`z`) и извлекает (`x`) его в указанную директорию (`-C`).

#### Вариант 2: scp

Используется, если нужно сохранить архивный файл .tar.gz на целевом сервере.
- `tar -czf project.tar.gz -C /путь/к infra-monitoring-project` — создание архива на исходной машине;
- `scp project.tar.gz user@remote_ip:/куда/положить/` — передача архива через scp;
- `tar -xzf project.tar.gz -C /куда/распаковать` — распаковка на целевом сервере (после подключения по SSH).

## 5. Деплой

```bash
ssh deploy@203.0.113.10
cd ~/apps/infra-monitoring-project
docker compose up -d
./check_api.sh http://localhost:80
```

### Пример полного деплоя одной последовательностью команд

```bash
SERVER="deploy@203.0.113.10"

# 1. Передать актуальную версию проекта
cd ~
tar -czf - --exclude='.git' --exclude='*.log' --exclude='traffic' infra-monitoring-project \
  | ssh "$SERVER" "mkdir -p ~/apps && tar -xzf - -C ~/apps"

# 2. Перезапустить стек и проверить доступность сервиса
ssh "$SERVER" "cd ~/apps/infra-monitoring-project && docker compose up -d && ./check_api.sh http://localhost:80"
```

Если последняя команда выводит `API доступен`, деплой прошёл успешно.
