#!/bin/bash

source /kamui/params
source /etc/wireguard/params
unset username days

clear
echo ""
until [[ ! -z $username ]] && [[ ! $(cat /kamui/user_database.json | jq -r '(.wireguard[] | select(.username == "'$username'")).username') ]] && [[ $username == ?(+|-)+([a-zA-Z0-9]) ]]; do
	read -p "Username : " username
	[[ -z $username ]] && echo -e "[ERROR] Null input."
	[[ $(cat /kamui/user_database.json | jq -r '(.wireguard[] | select(.username == "'$username'")).username') ]] && echo -e "[ERROR] User already exist."
	[[ $username != ?(+|-)+([a-zA-Z0-9]) ]] && echo -e "[ERROR] Invalid characters."
done
until [[ $days == ?(+|-)+([0-9]) ]] && [[ ! $days -lt 1 ]]; do
	read -p "Duration (days) : " days
	[[ $days != ?(+|-)+([0-9]) ]] && echo -e "[ERROR] Invalid characters."
	[[ $days -lt 1 ]] && echo -e "[ERROR] Invalid duration."
done
expired=$(date "+%Y-%m-%d" -d "+$days days")

for dot_ip in {2..254}; do
	dot_exists=$(grep -c "10.66.66.${dot_ip}" /etc/wireguard/wg0.conf)
	if [[ ${dot_exists} == '0' ]]; then
		break
	fi
done
if [[ ${dot_exists} == '1' ]]; then
	echo "[ERROR] The subnet configured only supports 253 clients."
	echo ""
	exit 1
fi
client_ipv4="10.66.66.${dot_ip}"
client_priv_key=$(wg genkey)
client_pub_key=$(echo "${client_priv_key}" | wg pubkey)
client_pre_shared_key=$(wg genpsk)

echo "[Interface]
PrivateKey = ${client_priv_key}
Address = ${client_ipv4}/32
DNS = 8.8.8.8,8.8.4.4

[Peer]
PublicKey = ${server_pub_key}
PresharedKey = ${client_pre_shared_key}
Endpoint = ${endpoint}
AllowedIPs = 0.0.0.0/0" >> /kamui/wireguard/${username}.conf
echo -e "\n### Client ${username}
[Peer]
PublicKey = ${client_pub_key}
PresharedKey = ${client_pre_shared_key}
AllowedIPs = ${client_ipv4}/32" >> /etc/wireguard/wg0.conf
systemctl daemon-reload
systemctl restart wg-quick@wg0

cat /kamui/user_database.json | jq '.wireguard += [{"username": "'${username}'","expired": "'${expired}'"}]' > /kamui/user_database.json.tmp
mv /kamui/user_database.json.tmp /kamui/user_database.json

clear
echo ""
echo "Username : $username"
echo "Expired  : $(date -d "$expired" +"%d %b %Y")"
echo ""
echo -e "\e[4mConfig\e[24m"
echo ""
cat /kamui/wireguard/${username}.conf
echo ""
echo "Config Link: https://${installSubDomain}/wg/${username}.conf"
echo ""
echo -e "\e[4mQR Code\e[24m"
echo ""
qrencode -t ansiutf8 -l L < /kamui/wireguard/${username}.conf
echo ""
