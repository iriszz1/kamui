#!/bin/bash

source /kamui/params

data1=$(cat /kamui/user_database.json | jq -r '.xray.vless[].username')
data2=$(netstat -anp | grep ESTABLISHED | grep tcp6 | grep xray | grep ":443" | awk '{print $5}' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | cut -d' ' -f1 | sort | uniq)

clear
echo ""
echo "================================"
echo "   Vless (TLS) Login Monitor"
echo "--------------------------------"
n=0
for user in ${data1[@]}; do
	touch /tmp/ipxray.txt
	for ip in ${data2[@]}; do
		total=$(cat /var/log/xray/access-tls.log | grep -w ${user}@vless-${installSubDomain} | awk '{print $3}' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | cut -d' ' -f1 | sort | uniq | grep -w $ip)
		if [[ "$total" == "$ip" ]]; then
			echo -e "$total" >> /tmp/ipxray.txt
			n=$((n+1))
		fi
	done
	total=$(cat /tmp/ipxray.txt)
	if [[ -n "$total" ]]; then
		total2=$(cat /tmp/ipxray.txt | nl)
		echo -e "$user :"
		echo -e "$total2"
	fi
	rm -f /tmp/ipxray.txt
done
echo "--------------------------------"
echo "  Total logins: $n"
echo "================================"
echo ""
data3=$(netstat -anp | grep ESTABLISHED | grep tcp | grep xray | grep ":80" | awk '{print $5}' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | cut -d' ' -f1 | sort | uniq)
echo "================================"
echo "  Vless (No-TLS) Login Monitor"
echo "--------------------------------"
n=0
for user in ${data1[@]}; do
	touch /tmp/ipxray.txt
	for ip in ${data3[@]}; do
		total=$(cat /var/log/xray/access-ntls.log | grep -w ${user}@vless-${installSubDomain} | awk '{print $3}' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | cut -d' ' -f1 | sort | uniq | grep -w $ip)
		if [[ "$total" == "$ip" ]]; then
			echo -e "$total" >> /tmp/ipxray.txt
			n=$((n+1))
		fi
	done
	total=$(cat /tmp/ipxray.txt)
	if [[ -n "$total" ]]; then
		total2=$(cat /tmp/ipxray.txt | nl)
		echo -e "$user :"
		echo -e "$total2"
	fi
	rm -f /tmp/ipxray.txt
done
echo "--------------------------------"
echo "  Total logins: $n"
echo "================================"
echo ""
