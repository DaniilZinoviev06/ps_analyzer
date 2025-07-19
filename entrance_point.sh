#!/bin/bash

PROC_PATH="/proc"
PROCESSES_LOG="$(pwd)/logs/processes.txt"
STAT_LOG="$(pwd)/logs/stat_log.txt"
SETTINGS="configuration.txt"
PROCESSES_CPU_LOG="$(pwd)/logs/process_cpu_log.txt"

# постарался использовать много разных утилит, не только awk или cut
# можно было бы сделать еще проверки корректности выполнения команд, например, через $? и ветвление, если -eq не = 0

settings_func() {
    clear

    option_1=$(grep "exclude_ps_process=" "$SETTINGS" | awk -F '=' '{print $2}')
    option_2=$(grep "update_time=" "$SETTINGS" | awk -F '=' '{print $2}')
    option_3=$(grep "is_logged=" "$SETTINGS" | awk -F '=' '{print $2}')

    #echo "$option_1 $option_2 $option_3"

    while true; do

        echo -e "\n\e[97m-------------------------------------------------------\e[0m"
        echo -e "\n\e[34m|\e[0m \e[92m1 - Исключить процесс ps aux\e[0m $(if [ "$option_1" == "yes" ]; then echo "вкл"; else echo "выкл"; fi)\n"
        echo -e "\e[34m|\e[0m \e[92m2 - Задержка между итерациями\e[0m $option_2\n"
        echo -e "\e[34m|\e[0m \e[92m3 - Логировать процессы с наибольшей загрузкой CPU\e[0m $(if [ "$option_3" == "yes" ]; then echo "вкл"; else echo "выкл"; fi)\n"
        echo -e "\e[34m|\e[0m \e[92m4 - Назад\e[0m\n"
        echo -e "\e[97m-------------------------------------------------------\e[0m\n"
        read -p "Ввод: " choice

        case $choice in
            1)
                clear
                sed -i "s/^exclude_ps_process=.*/exclude_ps_process=$(if [ "$option_1" == "yes" ]; then echo "no"; else echo "yes"; fi)/" "$SETTINGS"
                settings_func
            ;;

            2)
                clear

                read -p "Введите число: " choice_2

                # ошибки решил не выводить, в этом не вижу необходимости, просто сразу поток ошибок в null
                if test "$choice_2" -eq "$choice_2" 2>/dev/null; then
                    sed -i "s/^update_time=.*/update_time=$choice_2/" "$SETTINGS"
                    settings_func
                else
                    echo "$choice - не число"
                    settings_func
                fi
            ;;

            3)
                clear
                sed -i "s/^is_logged=.*/is_logged=$(if [ "$option_3" == "yes" ]; then echo "no"; else echo "yes"; fi)/" "$SETTINGS"
                settings_func
            ;;

            4)
                clear
                main
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

# Выводить можно очень много информации, но я решил не выводить все
# Иначе вывод будет выглядеть нечитаемо
process_data() {
    echo -e "\e[34m-----------------------------------------\e[0m\n"
    echo -e "     \e[92mПодробная информация о процессе\e[0m\n"
    echo -e "\e[34m-----------------------------------------\e[0m\n"

    echo -e "\n\e[92mОсновная информация\e[0m"
    cat "$PROC_PATH/$1/status" | grep -E "Name|State|Threads"

    echo -e "\n\e[92mВиртуальная память\e[0m"
    echo "Общий размер, используемый процессом: $(cat "$PROC_PATH/$1/statm" | awk '{print $1}')"
    echo "Размер физически-используемой памяти: $(cat "$PROC_PATH/$1/statm" | awk '{print $2}')"

    echo -e "\n\e[92mСетевые интерфейсы процесса\e[0m"
    cat "$PROC_PATH/$1/net/dev"

    echo -e "\n\e[92mВвод-вывод (байт)\e[0m"
    echo "Прочитано из ФС процессом: $(cat "$PROC_PATH/$1/io" | grep "rchar" | sed 's/rchar://')"
    echo "Записано в ФС процессом: $(cat "$PROC_PATH/$1/io" | grep "wchar" | sed 's/wchar://')"
    echo "Количество сисколов (чтение): $(cat "$PROC_PATH/$1/io" | grep "syscr" | sed 's/syscr://')"
    echo "Количество сисколов (запись): $(cat "$PROC_PATH/$1/io" | grep "syscw" | sed 's/syscw://')"

    local p_name=$(grep "Name" "$PROC_PATH/$1/status" | awk '{print $2}')
    # здесь доп информация journalctl, в /var/log/ особо ничего не нашел
    echo -e "\n\e[92mПоследние логи с процессом\e[0m"
    journalctl _PID=$1 | tail -n 5

    echo -e "\n\e[92mПоследние логи с приложением\e[0m"
    journalctl -xe | grep "$p_name" | tail -n 5

    echo -e "\n\e[34m-----------------------------------------\e[0m\n"
}

# фун-я с бесконечным циклом, можно было бы еще,
# например, через рекурсию сделать
ps_analyser() {

    option_1=$(grep "exclude_ps_process=" "$SETTINGS" | awk -F '=' '{print $2}')
    option_2=$(grep "update_time=" "$SETTINGS" | awk -F '=' '{print $2}')
    option_3=$(grep "is_logged=" "$SETTINGS" | awk -F '=' '{print $2}')

    while true; do

        clear

        # извлекаю данные через утилиту cut, до этого использую tr с флагом -s,
        # чтобы избавиться от двойных пробелов, потому что до этого вывод был некорректным
        ps aux | tr -s ' ' | cut -d ' ' -f 2,3,11 | tail -n +2 > $PROCESSES_LOG

        # не учитываем ps процесс, он часто показывает 100 cpu, по нему нет данных в /proc
        # я решил его исключить, но это опционально
        if [ "$option_1" == "yes" ]; then
            sed -i '/ps/d' $PROCESSES_LOG
        fi

        # сортировка в файле, 2 столбец
        sort -k2,2n "$PROCESSES_LOG" > process_file && mv process_file "$PROCESSES_LOG"

        read proccess_id cpu process_name <<< $(tail -n 1 $PROCESSES_LOG)

        # логирование процессов в файл
        if [ "$option_3" == "yes" ]; then
            # взял с SoF
            timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
            echo "$timestamp $proccess_id $process_name $cpu" >> $PROCESSES_CPU_LOG
        fi

        echo -e "\e[97mПроцесс (id): \e[0m\e[92m${proccess_id}\e[0m"
        echo -e "\e[97mЗагрузка CPU (%): \e[0m\e[92m${cpu}\e[0m\n"

        process_data $proccess_id

        sleep $option_2

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
                settings_func
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
