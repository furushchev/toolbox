#!/bin/bash

set -e

read -p "client name? [client]: " CLIENTNAME
read -s -p "Password?: " PASSWORD
CONF_PATH=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)/chap-secrets

echo "Generating conf file: $CONF_PATH"
cat <<EOF > ${CONF_PATH}
# Secrets for authentication using PAP
# client    server      secret      acceptable local IP addresses
$CLIENTNAME    *         $PASSWORD    *

EOF

docker run -d -p 1723:1723 --privileged -v "${CONF_PATH}:/etc/ppp/chap-secrets" --name vpn_pptp mobtitude/vpn-pptp

