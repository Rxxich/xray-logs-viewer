#!/bin/bash

GITHUB_USER="Rxxich"
REPO_NAME="xray-logs-viewer"
RAW_URL="https://raw.githubusercontent.com/$GITHUB_USER/$REPO_NAME/main"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Ошибка: Запустите от имени root${NC}"
  exit 1
fi

echo -e "${CYAN}--- Настройка пути к логам ---${NC}"
DEFAULT_PATH="/var/log/remnanode/access.log"
echo -e "Укажите путь к логам xray (access.log)."
echo -e "По умолчанию: ${YELLOW}$DEFAULT_PATH${NC}"

read -p "Путь: " USER_PATH < /dev/tty
FINAL_LOG_PATH=${USER_PATH:-$DEFAULT_PATH}

if [ ! -f "$FINAL_LOG_PATH" ]; then
    echo -e "${RED}Предупреждение: Файл $FINAL_LOG_PATH сейчас не существует.${NC}"
    echo -e "${YELLOW}Убедитесь, что путь верный, иначе скрипт не сможет ничего показать.${NC}"
fi

echo -e "${CYAN}--- Проверка зависимостей ---${NC}"
check_pkg() {
    dpkg -s "$1" >/dev/null 2>&1 || (apt update && apt install -y "$1")
}
check_pkg "python3"
check_pkg "python3-geoip2"
check_pkg "net-tools"
check_pkg "curl"

PY_SCRIPT_PATH="/usr/local/bin/xray_parser_logic.py"
MENU_SCRIPT_PATH="/usr/local/bin/xray_logs"

echo -e "${CYAN}--- Установка логики ---${NC}"

curl -sSL "$RAW_URL/xray_parser_logic.py" -o $PY_SCRIPT_PATH
curl -sSL "$RAW_URL/menu.sh" -o $MENU_SCRIPT_PATH

sed -i "s|REPLACE_ME|$FINAL_LOG_PATH|g" $MENU_SCRIPT_PATH

chmod +x $PY_SCRIPT_PATH
chmod +x $MENU_SCRIPT_PATH

echo -e "\n${GREEN}xray-logs-viewer v1.0 установлен!${NC}"
echo -e "Выбранный путь: ${YELLOW}$FINAL_LOG_PATH${NC}"
echo -e "Запуск: ${CYAN}xray_logs${NC}"
