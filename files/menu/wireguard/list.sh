#!/bin/bash

clear
n=0
echo -e ""
echo -e "==============================="
echo -e "  Username        Exp. Date"
echo -e "-------------------------------"
while read user; do
	[[ -z $user ]] && break
	expired=$(cat /kamui/user_database.json | jq -r '(.wireguard[] | select(.username == "'$user'")).expired')
	printf "  %-15s %s\n" $user "$(date -d "$expired" +"%d %b %Y")"
	n=$((n+1))
done <<< "$(cat /kamui/user_database.json | jq -r '.wireguard[].username')"
echo -e "-------------------------------"
echo -e "Total users : $n"
echo -e "==============================="
echo -e ""
