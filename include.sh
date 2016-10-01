#!/bin/bash

y-or-n() {
  local ans
  local que
  que=${@:-"Press: "}
  while true; do
    read -p "$que [Y/n]" ans
    case $ans in
      [Yy]* )
        (echo "Yes")
        return 0
        break
        ;;
      '' | [Nn]* )
        (echo "No")
        return 1
        break
        ;;
      * )
        echo Please answer Yes or No.
    esac
  done
}

