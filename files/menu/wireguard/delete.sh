#!/bin/bash

clear
if [[ ! $(cat /kamui/user_database.json | jq -r '.wireguard[].username') ]]; then
	echo ""
	echo "There are no WireGuard users."
	echo ""
	exit 0
fi

unset choice

n=0
echo ""
for username in $(cat /kamui/user_database.json | jq -r '.wireguard[].username'); do
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

sed -i "/^### Client ${username}\$/,/^$/d" /etc/wireguard/wg0.conf
if grep -q "### Client" /etc/wireguard/wg0.conf; then
	line=$(grep -n AllowedIPs /etc/wireguard/wg0.conf | tail -1 | awk -F: '{print $1}')
	head -${line} /etc/wireguard/wg0.conf > /etc/wireguard/wg0.conf.tmp
	mv /etc/wireguard/wg0.conf.tmp /etc/wireguard/wg0.conf
else
	head -6 /etc/wireguard/wg0.conf > /etc/wireguard/wg0.conf.tmp
	mv /etc/wireguard/wg0.conf.tmp /etc/wireguard/wg0.conf
fi
rm -f /kamui/wireguard/${username}.conf
cat /kamui/user_database.json | jq 'del(.wireguard[] | select(.username == "'$username'"))' > /kamui/user_database.json.tmp
mv /kamui/user_database.json.tmp /kamui/user_database.json

systemctl daemon-reload
systemctl restart wg-quick@wg0

clear
echo ""
echo "User '$username' has been deleted successfully."
echo ""
