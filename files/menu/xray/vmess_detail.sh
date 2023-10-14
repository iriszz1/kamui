#!/bin/bash

urlencode() {
	jq -R -r @uri <<< "$1"
}

clear
if [[ ! $(cat /kamui/user_database.json | jq -r '.xray.vmess[].username') ]]; then
	echo ""
	echo "There are no Vmess users."
	echo ""
	exit 0
fi

source /kamui/params
unset choice

n=0
echo ""
for username in $(cat /kamui/user_database.json | jq -r '.xray.vmess[].username'); do
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
uuid=$(cat /kamui/user_database.json | jq -r '.xray.vmess[] | select(.username == "'$username'").uuid')
expired=$(cat /kamui/user_database.json | jq -r '.xray.vmess[] | select(.username == "'$username'").expired')

echo "{
    \"add\":\"${installSubDomain}\",
    \"aid\":\"0\",
    \"host\":\"${installSubDomain}\",
    \"id\":\"${uuid}\",
    \"net\":\"ws\",
    \"path\":\"\\/vmess\",
    \"port\":\"443\",
    \"ps\":\"vmess_tls_ws_${username}\",
    \"tls\":\"tls\",
    \"sni\":\"${installSubDomain}\",
    \"type\":\"none\",
    \"v\":\"2\"
}" > /tmp/v2ray_client_tls.json

echo "{
    \"add\":\"${installSubDomain}\",
    \"aid\":\"0\",
    \"host\":\"${installSubDomain}\",
    \"id\":\"${uuid}\",
    \"net\":\"ws\",
    \"path\":\"\\/vmess\",
    \"port\":\"80\",
    \"ps\":\"vmess_ntls_ws_${username}\",
    \"tls\":\"none\",
    \"sni\":\"\",
    \"type\":\"none\",
    \"v\":\"2\"
}" > /tmp/v2ray_client_ntls.json

linkTLSWS="vmess://$(base64 -w 0 /tmp/v2ray_client_tls.json)"
linkNoTLSWS="vmess://$(base64 -w 0 /tmp/v2ray_client_ntls.json)"

rm -f /tmp/v2ray_client_tls.json
rm -f /tmp/v2ray_client_ntls.json

clear
echo ""
echo "Username : $username"
echo "Expired  : $(date -d "$expired" +"%d %b %Y")"
echo ""
echo -e "\e[4mVmess Settings\e[24m"
echo "Adress   : ${installSubDomain}"
echo "Port     : 443, 80 (No-TLS)"
echo "User ID  : ${uuid}"
echo "Alter ID : 0"
echo "Encrypt  : none"
echo "Transfer : ws"
echo "Type     : none"
echo "Host     : ${installSubDomain}"
echo "Path     : /vmess"
echo "TLS Type : tls"
echo "SNI      : ${installSubDomain}"
echo ""
echo -e "\e[4mConfig Link\e[24m"
echo "TLS WS    : $linkTLSWS"
echo "No-TLS WS : $linkNoTLSWS"
echo ""
echo -e "\e[4mConfig Link QR\e[24m"
echo "TLS WS    : https://any-qr.xp3.biz/api/?data=$(urlencode $linkTLSWS)"
echo "No-TLS WS : https://any-qr.xp3.biz/api/?data=$(urlencode $linkNoTLSWS)"
echo ""
