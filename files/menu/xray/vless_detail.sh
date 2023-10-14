#!/bin/bash

urlencode() {
	jq -R -r @uri <<< "$1"
}

if [[ ! $(cat /kamui/user_database.json | jq -r '.xray.vless[].username') ]]; then
	echo ""
	echo "There are no Vless users."
	echo ""
	exit 0
fi

source /kamui/params
unset choice

n=0
clear
echo ""
for username in $(cat /kamui/user_database.json | jq -r '.xray.vless[].username'); do
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
uuid=$(cat /kamui/user_database.json | jq -r '.xray.vless[] | select(.username == "'$username'").uuid')
expired=$(cat /kamui/user_database.json | jq -r '.xray.vless[] | select(.username == "'$username'").expired')

linkXTLS="vless://${uuid}@${installSubDomain}:443?security=tls&encryption=none&type=tcp&sni=${installSubDomain}&flow=xtls-rprx-vision#vless_xtls_${username}"
linkTLSWS="vless://${uuid}@${installSubDomain}:443?security=tls&encryption=none&type=ws&headerType=none&path=%252Fvless&sni=${installSubDomain}&host=${installSubDomain}#vless_tls_ws_${username}"
linkNoTLS="vless://${uuid}@${installSubDomain}:80?security=none&encryption=none&type=tcp#vless_ntls_${username}"
linkNoTLSWS="vless://${uuid}@${installSubDomain}:80?security=none&encryption=none&type=ws&headerType=none&path=%252Fvless&host=${installSubDomain}#vless_ntls_ws_${username}"

clear
echo ""
echo "Username : $username"
echo "Expired  : $(date -d "$expired" +"%d %b %Y")"
echo ""
echo -e "\e[4mVless Settings\e[24m"
echo "Address  : $installSubDomain"
echo "Port     : 443, 80 (No-TLS)"
echo "User ID  : $uuid"
echo "Encrypt  : None"
echo "Transfer : tcp, ws"
echo "Type     : none"
echo "Flow     : xtls-rprx-vision"
echo "TLS Type : tls, none (No-TLS)"
echo "SNI      : $installSubDomain"
echo "Host     : $installSubDomain"
echo "Path     : /vless"
echo ""
echo -e "\e[4mConfig Link\e[24m"
echo "XTLS      : $linkXTLS"
echo "TLS WS    : $linkTLSWS"
echo "No-TLS    : $linkNoTLS"
echo "No-TLS WS : $linkNoTLSWS"
echo ""
echo -e "\e[4mConfig Link QR\e[24m"
echo "XTLS      : https://any-qr.xp3.biz/api/?data=$(urlencode $linkXTLS)"
echo "TLS WS    : https://any-qr.xp3.biz/api/?data=$(urlencode $linkTLSWS)"
echo "No-TLS    : https://any-qr.xp3.biz/api/?data=$(urlencode $linkNoTLS)"
echo "No-TLS WS : https://any-qr.xp3.biz/api/?data=$(urlencode $linkNoTLSWS)"
echo ""
