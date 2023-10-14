#!/bin/bash

checkService() {
	if [[ "$(systemctl is-active $1)" == "active" ]]; then
		echo "Running"
	else
		echo "Not Running"
	fi
}

checkPID () {
	if pgrep $1 > /dev/null; then
		echo "Running"
	else
		echo "Not Running"
	fi
}

checkScreen() {
	if screen -ls | grep -qw $1; then
		echo "Running"
	else
		echo "Not Running"
	fi
}

clear
echo ""
echo -e "\e[4mService Status\e[24m"
echo ""
echo "Dropbear                : $(checkPID dropbear)"
echo "dnstt                   : $(checkScreen dnstt)"
echo "UDP Custom              : $(checkScreen udp-custom)"
echo "BadVPN UDPGw            : $(checkScreen badvpn)"
echo "Squid Proxy             : $(checkService squid)"
echo "OHP (Dropbear)          : $(checkScreen ohp-dropbear)"
echo "OHP (OpenVPN)           : $(checkScreen ohp-openvpn)"
echo "Python Proxy (Dropbear) : $(checkScreen ws-dropbear)"
echo "Python Proxy (OpenVPN)  : $(checkScreen ws-openvpn)"
echo "OpenVPN (UDP)           : $(checkService openvpn@udp)"
echo "OpenVPN (TCP)           : $(checkService openvpn@tcp)"
echo "WireGuard               : $(checkService wg-quick@wg0)"
echo "Xray (TLS)              : $(checkService xray@tls)"
echo "Xray (HTTP)             : $(checkService xray@ntls)"
echo "Nginx                   : $(checkService nginx)"
echo "Stunnel                 : $(checkPID stunnel)"
echo "Fail2Ban                : $(checkService fail2ban)"
echo "DDoS Deflate            : $(checkService ddos)"
echo ""
