#!/bin/bash

GITHUB_USER="Rxxich"
REPO_NAME="xray-logs-viewer"
RAW_URL="https://raw.githubusercontent.com/$GITHUB_USER/$REPO_NAME/main"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo "Запустите от имени root"
  exit 1
fi

echo -e "${CYAN}--- Настройка Xray Logs Viewer ---${NC}"
DEFAULT_PATH="/var/log/remnanode/access.log"
read -p "Укажите путь к access.log (default: $DEFAULT_PATH): " USER_PATH
FINAL_LOG_PATH=${USER_PATH:-$DEFAULT_PATH}

apt update && apt install -y python3 python3-geoip2 net-tools curl

curl -sSL "$RAW_URL/xray_parser_logic.py" -o /usr/local/bin/xray_parser_logic.py
curl -sSL "$RAW_URL/menu.sh" -o /usr/local/bin/xray_logs

sed -i "s|REPLACE_ME|$FINAL_LOG_PATH|g" /usr/local/bin/xray_logs

chmod +x /usr/local/bin/xray_parser_logic.py
chmod +x /usr/local/bin/xray_logs

echo -e "\n${GREEN}Установка завершена! Запуск командой: xray_logs${NC}"