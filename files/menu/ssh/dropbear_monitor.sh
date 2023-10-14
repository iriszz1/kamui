#!/bin/bash

clear
echo ""
echo -e "\e[4mDropbear Login Monitor\e[24m"
echo ""
echo "=============================================="
echo "  PID       Username       IP address"
echo "----------------------------------------------"
n=0
data=($(ps aux | grep -i dropbear | awk '{print $2}'))
for pid in "${data[@]}"; do
	num=$(journalctl -b -t dropbear | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$pid\]" | wc -l)
	user=$(journalctl -b -t dropbear | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$pid\]" | awk '{print $10}' | tr -d "'")
	ip=$(journalctl -b -t dropbear | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$pid\]" | awk '{print $12}')
	if [[ $num -eq 1 ]]; then
		printf "  %-9s %-14s %s\n" $pid $user $ip
		n=$((n+1))
	fi
done
echo "----------------------------------------------"
echo "  Total logins: $n"
echo "=============================================="
echo ""
