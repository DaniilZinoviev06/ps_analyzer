#!/bin/bash

PROC_PATH="/proc"
PROCESSES_LOG="$(pwd)/logs/processes.txt"
STAT_LOG="$(pwd)/logs/stat_log.txt"

#settings_func() {}

process_data() {
    echo -e "\e[34m-----------------------------------------\e[0m\n"
    echo -e "     \e[92mПодробная информация о процессе\e[0m\n"
    echo -e "\e[34m-----------------------------------------\e[0m\n"

    cat "$PROC_PATH/$1/status"

    echo -e "\n\e[34m-----------------------------------------\e[0m\n"
}

# фун-я с бесконечным циклом, можно было бы еще,
# например, через рекурсию сделать
ps_analyser() {
    while true; do

        clear

        # извлекаю данные через утилиту cut, до этого использую tr с флагом -s,
        # чтобы избавиться от двойных пробелов, потому что до этого вывод был некорректным
        ps aux | tr -s ' ' | cut -d ' ' -f 2,3 | tail -n +2 > $PROCESSES_LOG

        sort -k2,2n "$PROCESSES_LOG" > tmp && mv tmp "$PROCESSES_LOG"

        read proccess_id cpu <<< $(tail -n 1 $PROCESSES_LOG)

        echo -e "\e[97mПроцесс (id): \e[0m\e[92m${proccess_id}\e[0m"
        echo -e "\e[97mЗагрузка CPU (%): \e[0m\e[92m${cpu}\e[0m\n"

        process_data $proccess_id

        sleep 5

    done
}

main() {
    while true; do

        echo -e "\n\e[97m-------------------------------------------------------\e[0m"
        echo -e "\n\e[34m|\e[0m \e[92m1 - Начать мониторинг\e[0m\n"
        echo -e "\e[34m|\e[0m \e[92m2 - Настройки\e[0m\n"
        echo -e "\e[34m|\e[0m \e[92m3 - Выйти\e[0m\n"
        echo -e "\e[97m-------------------------------------------------------\e[0m\n"
        read -p "Ввод: " choice

        case $choice in
            1)
                clear
                ps_analyser
            ;;

            2)
                clear
                echo -e "2"
            ;;

            3)
                clear
                break
            ;;

            *)
                clear
                echo -e "\n-------------------------"
                echo "Повторите ввод"
                echo "-------------------------"
            ;;

        esac

    done
}

main
