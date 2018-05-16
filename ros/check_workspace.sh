#!/bin/bash

FORCE_UPDATE=false

prompt() {
  level="$1"
  RESET="\033[0m"
  if [ $level = "err" ]; then
    START="\033[1;31m"
  elif [ $level = "warn" ]; then
    START="\033[1;33m"
  elif [ $level = "info" ]; then
    START="\033[1;32m"
  fi
  shift
  echo -e "$START$@$RESET"
}

usage() {
  if [[ "$1" != "" ]]; then
    prompt err "$1"
    echo ""
  fi
  echo "$0 [-w|-f] [options]"
  echo "  Check package version in workspace"
  echo "  "
  echo "  -w, --workspace"
  echo "    Path to workspace"
  echo "  -f, --force-update"
  echo "    Force update to latest version"
  echo "  -h,--help"
  echo "    Show this help"
  exit 1
}

check_workspace() {
  WS=$1
  FORCE=$2

  PKGS=$(wstool info --only=path -t $WS)
  if [ "$PKGS" = "" ]; then
    prompt err "Invalid workspace $WS"
    exit 1
  fi

  for PKG in $PKGS; do
    CUR_TAG=$(cd $PKG && git describe --tags --abbrev=0)
    (cd $PKG && git fetch origin 2>&1 1>/dev/null)
    LATEST_TAG=$(cd $PKG && git tag | grep -e '^[0-9.]*$' | sort -Vr | head -n1)
    if [ "$CUR_TAG" != "$LATEST_TAG" ]; then
      prompt warn "Package $PKG -> Current $CUR_TAG / Latest $LATEST_TAG"
      read -p "Change to latest? [y/n]: " YN
      if [ "$YN" = "y" ]; then
        (cd $PKG && git checkout $LATEST_TAG)
      fi
    else
      prompt info "Package $PKG -> Current $CUR_TAG / Latest $LATEST_TAG"
    fi
  done
}

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -w|--workspace)
      WORKSPACE="$2"
      shift; shift
      ;;
    -f|--force-update)
      FORCE_UPDATE=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      usage "Unknown options: $1"
      ;;
  esac
done

if [ "$WORKSPACE" = "" ]; then
  WORKSPACE=$(pwd)
fi

check_workspace $WORKSPACE $FORCE_UPDATE
