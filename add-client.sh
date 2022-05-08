#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo $SCRIPT_DIR




if [ $# -eq 0 ]
then
	echo "must pass a client name as an arg: add-client.sh new-client"
else
	echo "Creating client config for: $1"
	mkdir -p /root/wg/clients/$1
	wg genkey | tee /root/wg/clients/$1/$1.priv | wg pubkey > /root/wg/clients/$1/$1.pub
	key=$(cat /root/wg/clients/$1/$1.priv) 
	ip="10.200.200."$(expr $(cat last-ip.txt | tr "." " " | awk '{print $4}') + 1)
	FQDN=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
  SERVER_PUB_KEY=$(cat /root/wg/keys/server_public_key)
  cat wg0-client.example.conf | sed -e 's/:CLIENT_IP:/'"$ip"'/' | sed -e 's|:CLIENT_KEY:|'"$key"'|' | sed -e 's|:SERVER_PUB_KEY:|'"$SERVER_PUB_KEY"'|' | sed -e 's|:SERVER_ADDRESS:|'"$FQDN"'|' > /root/wg/clients/$1/wg0.conf
	echo $ip > last-ip.txt
	cp SETUP.txt /root/wg/clients/$1/SETUP.txt
	tar czvf /root/wg/clients/$1.tar.gz /root/wg/clients/$1
	echo "Created config!"
	echo "Adding peer"
	sudo wg set wg0 peer $(cat /root/wg/clients/$1/$1.pub) allowed-ips $ip/32
	echo "Adding peer to hosts file"
	echo $ip" "$1 | sudo tee -a /etc/hosts
	sudo wg show
	qrencode -t ansiutf8 < /root/wg/clients/$1/wg0.conf
fi
