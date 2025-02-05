#!/usr/bin/env bash

trap "echo -e '\nЧтобы выйти из игры, введите q или Q'" SIGINT

generate_secret_number() {
      digits=({0..9})

      for ((i=0; i<4; i++)); do
        index=$((RANDOM % ${#digits[@]}))
        result+=${digits[$index]}

        digits=("${digits[@]:0:$index}" "${digits[@]:$((index + 1))}")
      done

      echo "$result"
}

secret_number=$(generate_secret_number)

history=""

move_count=0

echo "********************************************************************************
* Я загадал 4-значное число с неповторяющимися цифрами. На каждом ходу делайте *
* попытку отгадать загаданное число. Попытка - это 4-значное число с           *
* неповторяющимися цифрами.                                                    *
********************************************************************************"

while true; do
    read -r user_input

    if [[ $user_input == "q" || $user_input == "Q" ]]; then
        echo "Вы завершили игру. До свидания!"
        exit 1
    fi

    if ! [[ $user_input =~ ^[0-9]{4}$ ]] || [[ $(echo "$user_input" | grep -o . | sort | uniq | wc -l) -ne 4 ]]; then
        echo "Ошибка: Введите корректное 4-значное число с неповторяющимися цифрами."
        continue
    fi

    # Подсчет коров и быков
    bulls=0
    cows=0
    for ((i=0; i<4; i++)); do
        if [[ ${user_input:i:1} == ${secret_number:i:1} ]]; then
            ((bulls++))
        elif [[ $secret_number == *${user_input:i:1}* ]]; then
            ((cows++))
        fi
    done

    ((move_count++))
    history+="Ход $move_count: $user_input — Коровы: $cows, Быки: $bulls\n"

    echo -e "$history"

    if [[ $bulls -eq 4 ]]; then
        echo "Поздравляем! Вы угадали загаданное число $secret_number за $move_count ходов."
        exit 0
    fi

done
