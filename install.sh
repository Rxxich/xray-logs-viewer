#!/bin/bash

GITHUB_USER="Rxxich"
REPO_NAME="xray-logs-viewer"
BRANCH="main"
RAW_URL="https://raw.githubusercontent.com/$GITHUB_USER/$REPO_NAME/$BRANCH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Ошибка: Запустите от имени root${NC}"
  exit 1
fi

echo -e "${CYAN}--- Настройка Xray Logs Viewer ---${NC}"

DEFAULT_PATH="/var/log/remnanode/access.log"
echo -e "Укажите путь к логам xray (access.log)."
echo -n -e "По умолчанию [${YELLOW}$DEFAULT_PATH${NC}]: "
read USER_PATH < /dev/tty
FINAL_LOG_PATH=${USER_PATH:-$DEFAULT_PATH}

echo -e "${GREEN}Выбран путь: $FINAL_LOG_PATH${NC}"

echo -e "${CYAN}--- Установка зависимостей ---${NC}"
apt update && apt install -y python3 python3-geoip2 net-tools curl

PY_SCRIPT_PATH="/usr/local/bin/xray_parser_logic.py"
MENU_SCRIPT_PATH="/usr/local/bin/xray_logs"

echo -e "${CYAN}--- Скачивание компонентов ---${NC}"
curl -sSL "$RAW_URL/xray_parser_logic.py" -o $PY_SCRIPT_PATH
curl -sSL "$RAW_URL/menu.sh" -o $MENU_SCRIPT_PATH

sed -i "s|REPLACE_ME|$FINAL_LOG_PATH|g" $MENU_SCRIPT_PATH

chmod +x $PY_SCRIPT_PATH
chmod +x $MENU_SCRIPT_PATH

echo -e "\n${GREEN}Установка завершена!${NC}"
echo -e "Запуск: ${CYAN}xray_logs${NC}"
