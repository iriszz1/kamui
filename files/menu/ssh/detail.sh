#!/bin/bash

source /kamui/params

clear
if [[ ! $(cat /kamui/user_database.json | jq -r '.ssh[].username') ]]; then
	echo ""
	echo "There are no SSH users."
	echo ""
	exit 0
fi

unset choice

n=0
echo ""
while read expired; do
	account=$(echo $expired | cut -d: -f1)
	id=$(echo $expired | grep -v nobody | cut -d: -f3)
	exp=$(chage -l $account | grep "Account expires" | awk -F": " '{print $2}')

	if [[ $id -ge 1000 ]] && [[ $exp != "never" ]]; then
		n=$((n+1))
		user[$n]=$account
		echo "[$n] $account"
	fi
done < /etc/passwd
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
password=$(cat /kamui/user_database.json | jq -r '(.ssh[] | select(.username == "'$username'")).password')
expired=$(cat /kamui/user_database.json | jq -r '(.ssh[] | select(.username == "'$username'")).expired')

clear
echo ""
echo -e "\e[4mSSH User Information\e[24m"
echo "Hostname : $installSubDomain / $installIP"
echo "Username : $username"
echo "Password : $password"
echo "Expired  : $(date -d "$expired" +"%d %b %Y")"
echo ""
echo -e "\e[4mDropbear\e[24m"
echo "Port         : 80"
echo "Stunnel      : 465"
echo "Squid Proxy  : 8080"
echo "OHP          : 3128, 3129 (TLS)"
echo "Python Proxy : 8888, 8889 (TLS)"
echo "UDP Custom   : 1-65535 (Excluded ports: 7300, 53, 5300, 1194, 51820)"
echo ""
echo -e "\e[4mOpenVPN\e[24m"
echo "Download config : https://${installSubDomain}/ovpn/"
echo "Port            : 1194 (UDP), 194 (TCP)"
echo "Stunnel         : 990"
echo "Squid Proxy     : 8080"
echo "OHP             : 8000"
echo "Python Proxy    : 8989"
echo ""
echo -e "\e[4mdnstt\e[24m"
echo "Port        : 53 (UDP), 853 (TLS)"
echo "Name Server : ns-${installSubDomain}"
echo "Public Key  : $(cat /kamui/dnstt/server.pub)"
echo ""
