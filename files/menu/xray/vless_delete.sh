#!/bin/bash

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
email=${username}@vless-${installSubDomain}

cat /usr/local/etc/xray/tls.json | jq 'del(.inbounds[0].settings.clients[] | select(.email == "'${email}'"))' > /usr/local/etc/xray/tls.json.tmp
mv -f /usr/local/etc/xray/tls.json.tmp /usr/local/etc/xray/tls.json
cat /usr/local/etc/xray/tls.json | jq 'del(.inbounds[2].settings.clients[] | select(.email == "'${email}'"))' > /usr/local/etc/xray/tls.json.tmp
mv -f /usr/local/etc/xray/tls.json.tmp /usr/local/etc/xray/tls.json
cat /usr/local/etc/xray/ntls.json | jq 'del(.inbounds[0].settings.clients[] | select(.email == "'${email}'"))' > /usr/local/etc/xray/ntls.json.tmp
mv -f /usr/local/etc/xray/ntls.json.tmp /usr/local/etc/xray/ntls.json
cat /usr/local/etc/xray/ntls.json | jq 'del(.inbounds[2].settings.clients[] | select(.email == "'${email}'"))' > /usr/local/etc/xray/ntls.json.tmp
mv -f /usr/local/etc/xray/ntls.json.tmp /usr/local/etc/xray/ntls.json
systemctl daemon-reload
systemctl restart xray@tls
systemctl restart xray@ntls

cat /kamui/user_database.json | jq 'del(.xray.vless[] | select(.username == "'$username'"))' > /kamui/user_database.json.tmp
mv /kamui/user_database.json.tmp /kamui/user_database.json

clear
echo ""
echo "User '$username' has been deleted successfully."
echo ""
