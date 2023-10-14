#!/bin/bash

clear
echo ""
echo "=============================="
echo "  Username       Exp. Date    "
echo "------------------------------"
n=0
while read user; do
	[[ -z $user ]] && break
	expired=$(cat /kamui/user_database.json | jq -r '(.ssh[] | select(.username == "'$user'")).expired')
	printf "  %-14s %-15s\n" $user "$(date -d "$expired" +"%d %b %Y")"
	n=$((n+1))
done <<< "$(cat /kamui/user_database.json | jq -r '.ssh[].username')"
echo "------------------------------"
echo "  Total users : $n"
echo "=============================="
echo ""
