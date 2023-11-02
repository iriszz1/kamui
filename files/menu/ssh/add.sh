#!/bin/bash

source /kamui/params
unset username password days

clear
echo ""
until [[ ! -z $username ]] && [[ ! $(grep -w $username /etc/passwd) ]] && [[ $username == ?(+|-)+([a-zA-Z0-9]) ]]; do
	read -p "Username : " username
	[[ -z $username ]] && echo -e "[ERROR] Null input."
	[[ $(grep -w $username /etc/passwd) ]] && echo -e "[ERROR] User already exist."
	[[ $username != ?(+|-)+([a-zA-Z0-9]) ]] && echo -e "[ERROR] Invalid characters."
done
read -p "Password : " password
until [[ $days == ?(+|-)+([0-9]) ]] && [[ ! $days -lt 0 ]]; do
	read -p "Duration (days) : " days
	[[ $days != ?(+|-)+([0-9]) ]] && echo -e "[ERROR] Invalid characters."
	[[ $days -lt 1 ]] && echo -e "[ERROR] Invalid duration."
done
expired=$(date "+%Y-%m-%d" -d "+$days days")

useradd -e $expired -M -s /bin/false -p $(perl -e 'print crypt($ARGV[0], "password")' $password) $username
cat /kamui/user_database.json | jq '.ssh += [{"username": "'${username}'","password": "'${password}'","expired": "'${expired}'"}]' > /kamui/user_database.json.tmp
mv /kamui/user_database.json.tmp /kamui/user_database.json

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
