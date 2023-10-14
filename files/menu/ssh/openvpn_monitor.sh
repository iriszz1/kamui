#!/bin/bash

clear
echo ""
echo -e "\e[4mOpenVPN - TCP\e[24m"
echo ""
echo "====================================="
echo "  Username        IP address"
echo "-------------------------------------"
a=$(grep -n "Common Name,Real Address,Bytes Received,Bytes Sent,Connected Since" /var/log/openvpn/tcp-status.log | awk -F":" '{print $1}')
b=$(expr $(grep -n "ROUTING TABLE" /var/log/openvpn/tcp-status.log | awk -F":" '{print $1}') - 1)
c=$(expr ${b} - ${a})
n=0
while read login; do
	[[ -z $login ]] && break
	user=$(echo $login | awk '{print $1}')
	ip=$(echo $login | awk '{print $2}')
	printf "  %-15s %s\n" $user $ip
	n=$((n+1))
done <<< "$(cat /var/log/openvpn/tcp-status.log | head -n $b | tail -n $c | sed -e 's/,/\t/g')"
echo "-------------------------------------"
echo "  Total logins: $n"
echo "====================================="
echo ""
echo -e "\e[4mOpenVPN - UDP\e[24m"
echo ""
echo "====================================="
echo "  Username        IP address"
echo "-------------------------------------"
a=$(grep -n "Common Name,Real Address,Bytes Received,Bytes Sent,Connected Since" /var/log/openvpn/udp-status.log | awk -F":" '{print $1}')
b=$(expr $(grep -n "ROUTING TABLE" /var/log/openvpn/udp-status.log | awk -F":" '{print $1}') - 1)
c=$(expr ${b} - ${a})
n=0
while read login; do
	[[ -z $login ]] && break
	user=$(echo $login | awk '{print $1}')
	ip=$(echo $login | awk '{print $2}')
	printf "  %-15s %s\n" $user $ip
	n=$((n+1))
done <<< "$(cat /var/log/openvpn/udp-status.log | head -n $b | tail -n $c | sed -e 's/,/\t/g')"
echo "-------------------------------------"
echo "  Total logins: $n"
echo "====================================="
echo ""
