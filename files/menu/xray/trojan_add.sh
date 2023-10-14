#!/bin/bash

source /kamui/params
unset username days

urlencode() {
	jq -R -r @uri <<< "$1"
}

clear
echo ""
until [[ ! -z $username ]] && [[ ! $(cat /kamui/user_database.json | jq -r '(.xray.trojan[] | select(.username == "'$username'")).username') ]] && [[ $username == ?(+|-)+([a-zA-Z0-9]) ]]; do
	read -p "Username : " username
	[[ -z $username ]] && echo -e "[ERROR] Null input."
	[[ $(cat /kamui/user_database.json | jq -r '(.xray.trojan[] | select(.username == "'$username'")).username') ]] && echo -e "[ERROR] User already exist."
	[[ $username != ?(+|-)+([a-zA-Z0-9]) ]] && echo -e "[ERROR] Invalid characters."
done
read -p "Password : " password
until [[ $days == ?(+|-)+([0-9]) ]] && [[ ! $days -lt 1 ]]; do
	read -p "Duration (days) : " days
	[[ $days != ?(+|-)+([0-9]) ]] && echo -e "[ERROR] Invalid characters."
	[[ $days -lt 1 ]] && echo -e "[ERROR] Invalid duration."
done
expired=$(date "+%Y-%m-%d" -d "+$days days")
email=${username}@trojan-${installSubDomain}

cat /usr/local/etc/xray/tls.json | jq '.inbounds[1].settings.clients += [{"password": "'${password}'","email": "'${email}'"}]' > /usr/local/etc/xray/tls.json.tmp
mv -f /usr/local/etc/xray/tls.json.tmp /usr/local/etc/xray/tls.json
cat /usr/local/etc/xray/ntls.json | jq '.inbounds[1].settings.clients += [{"password": "'${password}'","email": "'${email}'"}]' > /usr/local/etc/xray/ntls.json.tmp
mv -f /usr/local/etc/xray/ntls.json.tmp /usr/local/etc/xray/ntls.json
systemctl daemon-reload
systemctl restart xray@tls
systemctl restart xray@ntls

cat /kamui/user_database.json | jq '.xray.trojan += [{"username": "'${username}'","password": "'${password}'","expired": "'${expired}'"}]' > /kamui/user_database.json.tmp
mv /kamui/user_database.json.tmp /kamui/user_database.json

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
