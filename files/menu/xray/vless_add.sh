#!/bin/bash

urlencode() {
	jq -R -r @uri <<< "$1"
}

source /kamui/params
unset username days

clear
echo ""
until [[ ! -z $username ]] && [[ ! $(cat /kamui/user_database.json | jq -r '(.xray.vless[] | select(.username == "'$username'")).username') ]] && [[ $username == ?(+|-)+([a-zA-Z0-9]) ]]; do
	read -p "Username : " username
	[[ -z $username ]] && echo -e "[ERROR] Null input."
	[[ $(cat /kamui/user_database.json | jq -r '(.xray.vless[] | select(.username == "'$username'")).username') ]] && echo -e "[ERROR] User already exist."
	[[ $username != ?(+|-)+([a-zA-Z0-9]) ]] && echo -e "[ERROR] Invalid characters."
done
until [[ $days == ?(+|-)+([0-9]) ]] && [[ ! $days -lt 0 ]]; do
	read -p "Duration (days) : " days
	[[ $days != ?(+|-)+([0-9]) ]] && echo -e "[ERROR] Invalid characters."
	[[ $days -lt 1 ]] && echo -e "[ERROR] Invalid duration."
done
expired=$(date "+%Y-%m-%d" -d "+$days days")
uuid=$(xray uuid)
while cat /kamui/user_database.json | jq -r '.xray.vless[].uuid' | grep -qw "$uuid"; do
    uuid=$(xray uuid)
done
email=${username}@vless-${installSubDomain}

cat /usr/local/etc/xray/tls.json | jq '.inbounds[0].settings.clients += [{"id": "'${uuid}'","flow": "xtls-rprx-vision","email": "'${email}'"}]' > /usr/local/etc/xray/tls.json.tmp
mv -f /usr/local/etc/xray/tls.json.tmp /usr/local/etc/xray/tls.json
cat /usr/local/etc/xray/tls.json | jq '.inbounds[2].settings.clients += [{"id": "'${uuid}'","email": "'${email}'"}]' > /usr/local/etc/xray/tls.json.tmp
mv -f /usr/local/etc/xray/tls.json.tmp /usr/local/etc/xray/tls.json
cat /usr/local/etc/xray/ntls.json | jq '.inbounds[0].settings.clients += [{"id": "'${uuid}'","email": "'${email}'"}]' > /usr/local/etc/xray/ntls.json.tmp
mv -f /usr/local/etc/xray/ntls.json.tmp /usr/local/etc/xray/ntls.json
cat /usr/local/etc/xray/ntls.json | jq '.inbounds[2].settings.clients += [{"id": "'${uuid}'","email": "'${email}'"}]' > /usr/local/etc/xray/ntls.json.tmp
mv -f /usr/local/etc/xray/ntls.json.tmp /usr/local/etc/xray/ntls.json
systemctl daemon-reload
systemctl restart xray@tls
systemctl restart xray@ntls

cat /kamui/user_database.json | jq '.xray.vless += [{"username": "'${username}'","uuid": "'${uuid}'","expired": "'${expired}'"}]' > /kamui/user_database.json.tmp
mv /kamui/user_database.json.tmp /kamui/user_database.json

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
