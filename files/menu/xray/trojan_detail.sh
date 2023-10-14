#!/bin/bash

urlencode() {
	jq -R -r @uri <<< "$1"
}

if [[ ! $(cat /kamui/user_database.json | jq -r '.xray.trojan[].username') ]]; then
	echo ""
	echo "There are no Trojan users."
	echo ""
	exit 0
fi

source /kamui/params
unset choice

n=0
clear
echo ""
for username in $(cat /kamui/user_database.json | jq -r '.xray.trojan[].username'); do
	n=$((n+1))
	user[$n]=$username
	echo "[$n] $username"
done
echo ""
echo "[x] Cancel"
echo ""
until [[ $choice -ge 1 ]] && [[ $choice -le $n ]] || [[ $choice == "x" ]]; do
	read -p "Choose user : " choice
	if [[ $choice -lt 1 ]] || [[ $choice -gt $n ]]; then
		[[ $choice != "x" ]] && echo "[ERROR] Invalid choice."
	fi
done
[[ $choice == "x" ]] && echo "" && exit
username=${user[${choice}]}
password=$(cat /kamui/user_database.json | jq -r '.xray.trojan[] | select(.username == "'$username'").password')
expired=$(cat /kamui/user_database.json | jq -r '.xray.trojan[] | select(.username == "'$username'").expired')

linkTLS="trojan://${password}@${installSubDomain}:443?security=tls&type=tcp&sni=${installSubDomain}#trojan_tls_${username}"
linkNoTLS="trojan://${password}@${installSubDomain}:80?security=none&type=tcp#trojan_ntls_${username}"

clear
echo ""
echo "Username : $username"
echo "Expired  : $(date -d "$expired" +"%d %b %Y")"
echo ""
echo -e "\e[4mTrojan Settings\e[24m"
echo "Address  : $installSubDomain"
echo "Port     : 443, 80 (No-TLS)"
echo "Password : $password"
echo "Flow     : -"
echo "Protocol : tcp"
echo "Type     : none"
echo "TLS Type : tls, none (No-TLS)"
echo "SNI      : $installSubDomain"
echo ""
echo -e "\e[4mConfig Link\e[24m"
echo "TLS    : $linkTLS"
echo "No-TLS : $linkNoTLS"
echo ""
echo -e "\e[4mConfig Link QR\e[24m"
echo "TLS    : https://any-qr.xp3.biz/api/?data=$(urlencode $linkTLS)"
echo "No-TLS : https://any-qr.xp3.biz/api/?data=$(urlencode $linkNoTLS)"
echo ""
