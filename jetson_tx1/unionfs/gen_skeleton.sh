#!/bin/bash

DIR=$1

[ -z "$DIR" ] && exit 1

linux_dir=(usr etc opt var)

for subdir in overlay master union; do
  dir="${DIR}/unionfs/${subdir}"
  if [ ! -e "${dir}" ]; then
    mkdir -p "${dir}"
  else
    if [ ! -d "${dir}" ]; then
      echo "${dir} must be directory"
      exit 1
    fi
  fi

  for dest in ${linux_dir[@]}; do
    mkdir -p "${dir}/${dest}"
  done
done
