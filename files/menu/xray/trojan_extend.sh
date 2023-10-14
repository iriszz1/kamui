#!/bin/bash

if [[ ! $(cat /kamui/user_database.json | jq -r '.xray.trojan[].username') ]]; then
	echo ""
	echo "There are no Trojan users."
	echo ""
	exit 0
fi

unset choice days

n=0
clear
echo ""
for username in $(cat /kamui/user_database.json | jq -r '.xray.trojan[].username'); do
	n=$((n+1))
	user[$n]=$username
	echo "[$n] $username"
done
echo ""
echo "[x] Cancel"
echo ""
until [[ $choice -ge 1 ]] && [[ $choice -le $n ]] || [[ $choice == "x" ]]; do
	read -p "Choose user : " choice
	if [[ ! $choice -ge 1 ]] || [[ ! $choice -le $n ]]; then
		[[ $choice != "x" ]] && echo "[ERROR] Invalid choice."
	fi
done
[[ $choice == "x" ]] && echo "" && exit
username=${user[${choice}]}

until [[ $days == ?(+|-)+([0-9]) ]] && [[ ! $days -lt 1 ]]; do
	read -p "Duration (days) : " days
	[[ $days != ?(+|-)+([0-9]) ]] && echo -e "[ERROR] Invalid characters."
	[[ $days -lt 1 ]] && echo -e "[ERROR] Invalid duration."
done

exp_old=$(cat /kamui/user_database.json | jq -r '(.xray.trojan[] | select(.username == "'$username'")).expired')
diff=$((($(date -d "${exp_old}" +%s)-$(date +%s))/(86400)))
duration=$(expr $diff + $days + 1)
exp_new=$(date -d +${duration}days +%Y-%m-%d)

cat /kamui/user_database.json | jq '(.xray.trojan[] | select(.username == "'$username'")).expired |= "'$exp_new'"' > /kamui/user_database.json.tmp
mv /kamui/user_database.json.tmp /kamui/user_database.json

clear
echo ""
echo "User '$username' validity has been extended successfully."
echo ""
echo "New expired : $(date -d "$exp_new" +"%d %b %Y")"
echo ""
