#!/bin/bash

clear
if [[ ! $(cat /kamui/user_database.json | jq -r '.ssh[].username') ]]; then
	echo ""
	echo "There are no SSH users."
	echo ""
	exit 0
fi

unset choice days

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
until [[ $days == ?(+|-)+([0-9]) ]] && [[ ! $days -lt 1 ]]; do
	read -p "Duration (days) : " days
	[[ $days != ?(+|-)+([0-9]) ]] && echo -e "[ERROR] Invalid characters."
	[[ $days -lt 1 ]] && echo -e "[ERROR] Invalid duration."
done

exp_old=$(chage -l $username | grep "Account expires" | awk -F": " '{print $2}')
diff=$((($(date -d "${exp_old}" +%s)-$(date +%s))/(86400)))
duration=$(expr $diff + $days + 1)
exp_new=$(date -d +${duration}days +%Y-%m-%d)

chage -E $exp_new $username
cat /kamui/user_database.json | jq '(.ssh[] | select(.username == "'$username'")).expired |= "'$exp_new'"' > /kamui/user_database.json.tmp
mv /kamui/user_database.json.tmp /kamui/user_database.json

clear
echo ""
echo "User '$username' validity has been extended successfully."
echo ""
echo "New expired : $(date -d "$exp_new" +"%d %b %Y")"
echo ""
