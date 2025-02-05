#!/usr/bin/env bash

trap "echo -e '\nЧтобы выйти из игры, введите q или Q'" SIGINT

A=(8 7 6 5 4 3 2 1)
B=()
C=()
step=1

print_towers() {
  for ((i = 8 - 1; i >= 0; i--)); do
    echo -e "|${A[i]:-" "}|\t|${B[i]:-" "}|\t|${C[i]:-" "}|"
  done
  echo -e "+-+\t+-+\t+-+\n A \t B \t C"
}

move_disk() {
  local -n from=$1
  local -n to=$2

  if [ ${#from[@]} -eq 0 ]; then
    echo "Ошибка: Башня $1 пуста. Повторите ход."
    return 1
  fi

  local disk=${from[-1]}

  if [[ ${#to[@]} -ne 0 ]] && [[ $disk -gt ${to[-1]} ]]; then
    echo "Ошибка: Нельзя положить диск большего размера на меньший. Повторите ход."
    return 1
  fi

  unset 'from[-1]'
  to+=("$disk")
  return 0
}

check_victory() {
  if [[ "${B[*]}" == "8 7 6 5 4 3 2 1" || "${C[*]}" == "8 7 6 5 4 3 2 1" ]]; then
    echo "Поздравляем! Вы победили!"
    exit 0
  fi
}

while true; do
  print_towers
  echo -n "Ход № $step (откуда, куда): "
  read -r input

  input=$(echo "$input" | tr '[:lower:]' '[:upper:]' | tr -d '[:blank:]')

  if [[ $input == "Q" ]]; then
    echo "Вы завершили игру. До свидания!"
    exit 1
  fi

  if [[ ! $input =~ ^[ABC]{2}$ ]]; then
    echo "Ошибка: Введите два разных имени стеков (например, AB)."
    continue
  fi

  from_stack=${input:0:1}
  to_stack=${input:1}

  if [[ $from_stack == $to_stack ]]; then
    echo "Ошибка: Стек-отправитель и стек-получатель должны быть разными."
    continue
  fi

  if move_disk "$from_stack" "$to_stack"; then
    ((step++))
    check_victory
  fi
done
