#!/bin/bash

urlencode() {
	jq -R -r @uri <<< "$1"
}

source /kamui/params
unset username days

clear
echo ""
until [[ ! -z $username ]] && [[ ! $(cat /kamui/user_database.json | jq -r '(.xray.vmess[] | select(.username == "'$username'")).username') ]] && [[ $username == ?(+|-)+([a-zA-Z0-9]) ]]; do
	read -p "Username : " username
	[[ -z $username ]] && echo -e "[ERROR] Null input."
	[[ $(cat /kamui/user_database.json | jq -r '(.xray.vmess[] | select(.username == "'$username'")).username') ]] && echo -e "[ERROR] User already exist."
	[[ $username != ?(+|-)+([a-zA-Z0-9]) ]] && echo -e "[ERROR] Invalid characters."
done
until [[ $days == ?(+|-)+([0-9]) ]] && [[ ! $days -lt 1 ]]; do
	read -p "Duration (days) : " days
	[[ $days != ?(+|-)+([0-9]) ]] && echo -e "[ERROR] Invalid characters."
	[[ $days -lt 1 ]] && echo -e "[ERROR] Invalid duration."
done
expired=$(date "+%Y-%m-%d" -d "+$days days")
uuid=$(xray uuid)
while cat /kamui/user_database.json | jq -r '.xray.vmess[].uuid' | grep -qw "$uuid"; do
    uuid=$(xray uuid)
done
email=${username}@vmess-${installSubDomain}

cat /usr/local/etc/xray/tls.json | jq '.inbounds[3].settings.clients += [{"id": "'${uuid}'","email": "'${email}'"}]' > /usr/local/etc/xray/tls.json.tmp
mv -f /usr/local/etc/xray/tls.json.tmp /usr/local/etc/xray/tls.json
cat /usr/local/etc/xray/ntls.json | jq '.inbounds[3].settings.clients += [{"id": "'${uuid}'","email": "'${email}'"}]' > /usr/local/etc/xray/ntls.json.tmp
mv -f /usr/local/etc/xray/ntls.json.tmp /usr/local/etc/xray/ntls.json
systemctl daemon-reload
systemctl restart xray@tls
systemctl restart xray@ntls

cat /kamui/user_database.json | jq '.xray.vmess += [{"username": "'${username}'","uuid": "'${uuid}'","expired": "'${expired}'"}]' > /kamui/user_database.json.tmp
mv /kamui/user_database.json.tmp /kamui/user_database.json

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
