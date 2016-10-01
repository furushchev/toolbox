#!/bin/bash


export OVPN_DATA="ovpn-data"
export VPN_HOSTNAME=${HOSTNAME}
export CLIENTNAME="client"
export VPN_PORT=443

docker run --name ${OVPN_DATA} -v /etc/openvpn busybox
docker run --volumes-from ${OVPN_DATA} --rm kylemanna/openvpn ovpn_genconfig -u tcp://${VPN_HOSTNAME}:${VPN_PORT}
docker run --volumes-from ${OVPN_DATA} --rm -it kylemanna/openvpn ovpn_initpki
docker run --volumes-from ${OVPN_DATA} -d -p ${VPN_PORT}:1194/tcp --cap-add=NET_ADMIN kylemanna/openvpn
docker run --volumes-from ${OVPN_DATA} --rm -it kylemanna/openvpn easyrsa build-client-full ${CLIENTNAME} nopass
docker run --volumes-from ${OVPN_DATA} --rm kylemanna/openvpn ovpn_getclient ${CLIENTNAME} > ${CLIENTNAME}.ovpn
