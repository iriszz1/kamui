#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/kamui/cron

source /kamui/params
today=$(date +%Y-%m-%d)

while read user; do
	[[ -z $user ]] && break
	expired=$(cat /kamui/user_database.json | jq -r '(.ssh[] | select(.username == "'$user'")).expired')
	if [[ $expired < $today ]]; then
		userdel $user
		cat /kamui/user_database.json | jq 'del(.ssh[] | select(.username == "'$user'"))' > /kamui/user_database.json.tmp
		mv /kamui/user_database.json.tmp /kamui/user_database.json
	fi
done <<< "$(cat /kamui/user_database.json | jq -r '.ssh[].username')"
pkill dropbear
dropbear -Rw -p 85 -b /etc/db-issue.net
systemctl restart openvpn@udp
systemctl restart openvpn@tcp

while read user; do
	[[ -z $user ]] && break
	expired=$(cat /kamui/user_database.json | jq -r '(.wireguard[] | select(.username == "'$user'")).expired')
	if [[ $expired < $today ]]; then
		sed -i "/^### Client ${user}\$/,/^$/d" /etc/wireguard/wg0.conf
		if grep -q "### Client" /etc/wireguard/wg0.conf; then
			line=$(grep -n AllowedIPs /etc/wireguard/wg0.conf | tail -1 | awk -F: '{print $1}')
			head -${line} /etc/wireguard/wg0.conf > /etc/wireguard/wg0.conf.tmp
			mv /etc/wireguard/wg0.conf.tmp /etc/wireguard/wg0.conf
		else
			head -6 /etc/wireguard/wg0.conf > /etc/wireguard/wg0.conf.tmp
			mv /etc/wireguard/wg0.conf.tmp /etc/wireguard/wg0.conf
		fi
		rm -f /kamui/wireguard/${user}.conf
		cat /kamui/user_database.json | jq 'del(.wireguard[] | select(.username == "'$user'"))' > /kamui/user_database.json.tmp
		mv /kamui/user_database.json.tmp /kamui/user_database.json
	fi
done <<< "$(cat /kamui/user_database.json | jq -r '.wireguard[].username')"

while read user; do
	[[ -z $user ]] && break
	expired=$(cat /kamui/user_database.json | jq -r '(.xray.vless[] | select(.username == "'$user'")).expired')
	if [[ $expired < $today ]]; then
		email=${user}@vless-${installSubDomain}
		cat /usr/local/etc/xray/tls.json | jq 'del(.inbounds[0].settings.clients[] | select(.email == "'${email}'"))' > /usr/local/etc/xray/tls.json.tmp
		mv -f /usr/local/etc/xray/tls.json.tmp /usr/local/etc/xray/tls.json
		cat /usr/local/etc/xray/tls.json | jq 'del(.inbounds[2].settings.clients[] | select(.email == "'${email}'"))' > /usr/local/etc/xray/tls.json.tmp
		mv -f /usr/local/etc/xray/tls.json.tmp /usr/local/etc/xray/tls.json
		cat /usr/local/etc/xray/ntls.json | jq 'del(.inbounds[0].settings.clients[] | select(.email == "'${email}'"))' > /usr/local/etc/xray/ntls.json.tmp
		mv -f /usr/local/etc/xray/ntls.json.tmp /usr/local/etc/xray/ntls.json
		cat /usr/local/etc/xray/ntls.json | jq 'del(.inbounds[2].settings.clients[] | select(.email == "'${email}'"))' > /usr/local/etc/xray/ntls.json.tmp
		mv -f /usr/local/etc/xray/ntls.json.tmp /usr/local/etc/xray/ntls.json
		cat /kamui/user_database.json | jq 'del(.xray.vless[] | select(.username == "'$user'"))' > /kamui/user_database.json.tmp
		mv /kamui/user_database.json.tmp /kamui/user_database.json
	fi
done <<< "$(cat /kamui/user_database.json | jq -r '.xray.vless[].username')"

while read user; do
	[[ -z $user ]] && break
	if [[ $expired < $today ]]; then
		email=${user}@vmess-${installSubDomain}
		cat /usr/local/etc/xray/tls.json | jq 'del(.inbounds[3].settings.clients[] | select(.email == "'${email}'"))' > /usr/local/etc/xray/tls.json.tmp
		mv -f /usr/local/etc/xray/tls.json.tmp /usr/local/etc/xray/tls.json
		cat /usr/local/etc/xray/ntls.json | jq 'del(.inbounds[3].settings.clients[] | select(.email == "'${email}'"))' > /usr/local/etc/xray/ntls.json.tmp
		mv -f /usr/local/etc/xray/ntls.json.tmp /usr/local/etc/xray/ntls.json
		cat /kamui/user_database.json | jq 'del(.xray.vmess[] | select(.username == "'$user'"))' > /kamui/user_database.json.tmp
		mv /kamui/user_database.json.tmp /kamui/user_database.json
	fi
done <<< "$(cat /kamui/user_database.json | jq -r '.xray.vmess[].username')"

while read user; do
	[[ -z $user ]] && break
	if [[ $expired < $today ]]; then
		email=${user}@trojan-${installSubDomain}
		cat /usr/local/etc/xray/tls.json | jq 'del(.inbounds[1].settings.clients[] | select(.email == "'${email}'"))' > /usr/local/etc/xray/tls.json.tmp
		mv -f /usr/local/etc/xray/tls.json.tmp /usr/local/etc/xray/tls.json
		cat /usr/local/etc/xray/ntls.json | jq 'del(.inbounds[1].settings.clients[] | select(.email == "'${email}'"))' > /usr/local/etc/xray/ntls.json.tmp
		mv -f /usr/local/etc/xray/ntls.json.tmp /usr/local/etc/xray/ntls.json
		cat /kamui/user_database.json | jq 'del(.xray.trojan[] | select(.username == "'$user'"))' > /kamui/user_database.json.tmp
		mv /kamui/user_database.json.tmp /kamui/user_database.json
	fi
done <<< "$(cat /kamui/user_database.json | jq -r '.xray.trojan[].username')"

systemctl daemon-reload
systemctl restart wg-quick@wg0
systemctl restart xray@tls
systemctl restart xray@ntls
