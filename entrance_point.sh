#!/bin/bash

#ps_analyser() {}

#settings_func() {}

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
                echo -e "1"
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
                echo "Не отчайвайтесь)"
                echo "-------------------------"
            ;;

        esac

    done
}

main
