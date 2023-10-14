#!/bin/bash

source /kamui/params

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
expired=$(cat /kamui/user_database.json | jq -r '(.wireguard[] | select(.username == "'$username'")).expired')

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
