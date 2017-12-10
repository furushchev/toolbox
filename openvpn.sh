#!/bin/bash

OVPN_DATA="ovpn-data"

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

get_hostname() {
  OVPN_HOSTNAME=$(host -TtA $(hostname -s)|grep "has address"|awk '{print $1}')
  if [[ "${OVPN_HOSTNAME}" = "" ]]; then
    OVPN_HOSTNAME=$(hostname -s)
  fi
  echo $OVPN_HOSTNAME
}

usage() {
  if [[ "$1" != "" ]]; then
    prompt err "$1"
    echo ""
  fi
  echo "$0 [--init|--add|--remove|--list] [options]"
  echo "  Docker OpenVPN Server Configurator"
  echo "  "
  echo "  -i,--init"
  echo "    Initialize openvpn server on docker"
  echo "      Options:"
  echo "        -p, --port: Port number used by OpenVPN"
  echo "        --tcp: Use TCP Protocol for OpenVPN"
  echo "  -a,--add <name>"
  echo "    Generate client certificate"
  echo "    name: client name"
  echo "  -r,--remove <name>"
  echo "    Revoke named certificate"
  echo "    name: client name"
  echo "  -l,--list"
  echo "    List all clients"
  echo "  -h,--help"
  echo "    Show this help"
  exit 1
}

error_handler() {
  docker volume rm -f "$OVPN_DATA"
  trap - ERR
  exit 1
}

print_upstart() {
cat <<EOF
description "Docker container for OpenVPN server"
start on filesystem and started docker
stop on runlevel [!2345]
respawn
script
  exec docker run -v $OVPN_DATA:/etc/openvpn --rm -p $PORT:1194/$PROTO --cap-add=NET_ADMIN kylemanna/openvpn
end script
EOF
}

ovpn_init() {
  # check arguments
  if [ -z ${PORT+x} ]; then
    read -p "VPN Port? [1194]: " PORT
    if [ "$PORT" = "" ]; then
      PORT=1194
    fi
    if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
      usage "Invalid port: $PORT"
    fi
  fi
  if [ -z ${PROTO+x} ]; then
    read -p "VPN Protocol? [udp]: " PROTO
    if [ "$PROTO" = "" ]; then
      PROTO="udp"
    fi
    if [ "$PROTO" != "tcp" ] && [ "$PROTO" != "udp" ]; then
      usage "Invalid protocol: $PROTO"
    fi
  fi

  COMFIRM=n
  OVPN_HOSTNAME=$(get_hostname)
  while [ "$CONFIRM" != "y" ]; do
    prompt warn '*****************************'
    prompt warn " Data Volume Container: $OVPN_DATA"
    prompt warn " VPN Host: $OVPN_HOSTNAME"
    prompt warn " VPN Port: $PORT/$PROTO"
    prompt warn " NOTE:"
    prompt warn "   If you asked password, please type onetime password as you like."
    prompt warn "   If you asked CA name, please type hostname. your hostname is ${OVPN_HOSTNAME}"
    prompt warn '*****************************'
    read -p "Do you agree and understand? [y/n]: " CONFIRM
  done
  prompt info "OK, let's go ahead!"

  docker volume create --name $OVPN_DATA
  trap error_handler ERR
  docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u $PROTO://$OVPN_HOSTNAME
  docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki
  docker run -v $OVPN_DATA:/etc/openvpn -d -p ${PORT}:1194/${PROTO} --cap-add=NET_ADMIN kylemanna/openvpn
  prompt info "OpenVPN Server container started"
  prompt info "If you want to register OpenVPN server as startup service,"
  prompt info "Put upstart script to appropriate path (e.g. /etc/init/docker-openvpn.conf ):"
  print_upstart
}

ovpn_list() {
  docker run --rm -it -v $OVPN_DATA:/etc/openvpn kylemanna/openvpn ovpn_listclients
}

ovpn_add() {
  if [ "$CLIENTNAME" = "" ]; then
    read -p "Client name? : " CLIENTNAME
    if [ "$CLIENTNAME" = "" ]; then
      usage "Client name must not be empty"
    fi
  fi
  CONFIRM=n
  read -p "Add client $CLIENTNAME? [y/n]: " CONFIRM
  if [ "$CONFIRM" != "y" ]; then
    prompt warn "Aborted"
    exit 1
  fi

  docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full $CLIENTNAME nopass
  docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient $CLIENTNAME > "${CLIENTNAME}.ovpn"
  prompt info "Created client configuration file: ${CLIENTNAME}.ovpn"
}

ovpn_remove() {
  if [ "$CLIENTNAME" = "" ]; then
    read -p "Client name? : " CLIENTNAME
    if [ "$CLIENTNAME" = "" ]; then
      usage "Client name must not be empty"
    fi
  fi
  CONFIRM=n
  read -p "Remove client $CLIENTNAME? [y/n]: " CONFIRM
  if [ "$CONFIRM" != "y" ]; then
    prompt warn "Aborted"
    exit 1
  fi

  docker run --rm -it -v $OVPN_DATA:/etc/openvpn kylemanna/openvpn ovpn_revokeclient $CLIENTNAME remove
}

exec_command() {
  CMD="$1"
  if [ "$CMD" =  "init" ]; then
    ovpn_init
  elif [ "$CMD" = "add" ]; then
    ovpn_add
  elif [ "$CMD" = "remove" ]; then
    ovpn_remove
  elif [ "$CMD" = "list" ]; then
    ovpn_list
  fi
}

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--init)
      COMMAND="init"
      shift
      ;;
    -a|--add)
      COMMAND="add"
      CLIENTNAME="$2"
      shift; shift
      ;;
    -r|--remove)
      COMMAND="remove"
      CLIENTNAME="$2"
      shift; shift
      ;;
    -l|--list)
      COMMAND="list"
      shift
      ;;
    -p|--port)
      PORT="$2"
      shift
      ;;
    --tcp)
      PROTO="tcp"
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)  # unknown options
      usage "Unknown options: $1"
      ;;
  esac
done

if [ "$COMMAND" = "" ]; then
  usage "Unknown command"
fi

exec_command $COMMAND
