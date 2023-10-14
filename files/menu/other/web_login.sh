#!/bin/bash

clear
echo ""
echo -e "\e[4mWeb directory login\e[24m"
echo ""
until [[ ! -z $username ]] && [[ $username == ?(+|-)+([a-zA-Z0-9]) ]]; do
	read -p "Username : " username
	[[ -z $username ]] && echo -e "[ERROR] Null input."
	[[ $username != ?(+|-)+([a-zA-Z0-9]) ]] && echo -e "[ERROR] Invalid characters."
done
read -p "Password : " password
htpasswd -bc /etc/nginx/conf.d/.htpasswd $username $password
clear
echo ""
echo -e "\e[4mWeb directory login\e[24m"
echo ""
echo "Login for config web directory set successfully."
echo ""
echo "Username : $username"
echo "Password : $password"
echo ""
