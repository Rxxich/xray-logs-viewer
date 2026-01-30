#!/bin/bash
G='\033[0;32m'
Y='\033[1;33m'
C='\033[0;36m'
R='\033[0;31m'
NC='\033[0m'

PY_LOGS="/usr/local/bin/xray_parser_logic.py"
LOG_PATH="REPLACE_ME"

while true; do
    clear
    echo -e "${G}==========================================${NC}"
    echo -e "${G}         УПРАВЛЕНИЕ ЛОГАМИ XRAY           ${NC}"
    echo -e "${G}==========================================${NC}"
    echo -e "${Y}1)${G} Запуск в основном режиме (только домены)${NC}"
    echo -e "${Y}2)${G} Запуск в основном режиме (+ IP адреса)${NC}"
    echo -e "${Y}3)${G} Запуск в режиме сводки (Unique IPs)${NC}"
    echo -e "${Y}4)${G} Только активные сейчас (Online)${NC}"
    echo -e "${Y}5)${G} Просмотр логов в реальном времени${NC}"
    echo -e "${Y}6)${G} Поиск по адресу или домену (Search)${NC}"
    echo -e "${R}0)${G} Выход${NC}"
    echo -e "${G}==========================================${NC}"
    echo -n -e "Выберите вариант: ${Y}"
    read opt
    echo -e "${NC}"

    case $opt in
        1) python3 $PY_LOGS --path "$LOG_PATH"; echo -e "\n${C}Нажмите Enter...${NC}"; read ;;
        2) python3 $PY_LOGS --path "$LOG_PATH" --ip; echo -e "\n${C}Нажмите Enter...${NC}"; read ;;
        3) python3 $PY_LOGS --path "$LOG_PATH" --summary; echo -e "\n${C}Нажмите Enter...${NC}"; read ;;
        4) python3 $PY_LOGS --path "$LOG_PATH" --online; echo -e "\n${C}Нажмите Enter...${NC}"; read ;;
        5) (trap 'exit 0' SIGINT; tail -f "$LOG_PATH") ;;
        6) 
            echo -n -e "Введите запрос для поиска: "
            read term
            python3 $PY_LOGS --path "$LOG_PATH" --search "$term"
            echo -e "\n${C}Нажмите Enter...${NC}"; read ;;
        0) exit 0 ;;
        *) echo -e "${R}Ошибка.${NC}"; sleep 1 ;;
    esac
done