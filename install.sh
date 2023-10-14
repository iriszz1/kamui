#!/bin/bash

# Force curl IPv4
echo '--ipv4' >> ~/.curlrc

repoDir="https://raw.githubusercontent.com/iriszz1/kamui/main/"
source <(curl -s ${repoDir}files/others/link.sources)

cd

# Check root access
if [[ $EUID -ne 0 ]]; then
	echo -e "\nThis script must be run as root.\n"
	read -n 1 -r -s -p $"Press any key to continue ... "
	rm -f install.sh
	cat /dev/null > ~/.bash_history
	exit 1
fi

# Check OS
source '/etc/os-release'
if [[ "${ID}" != "debian" || "${VERSION_ID}" -lt "11" ]]; then
	echo -e "\nThis script is only for Debian 11 and newer.\n"
	read -n 1 -r -s -p $"Press any key to continue ... "
	rm -f install.sh
	cat /dev/null > ~/.bash_history
	exit 1
fi

# Check virtualization
virt=$(systemd-detect-virt)
if [[ $virt != "kvm" && $virt != "xen" && $virt != "hyperv" && $virt != "microsoft" ]]; then
	echo -e "\nYou are using unsupported virtualization.\n"
	read -n 1 -r -s -p $"Press any key to continue ... "
	rm -f install.sh
	cat /dev/null > ~/.bash_history
	exit 1
fi

# Update packages
echo "[INFO] Update packages"
sleep 2
apt update
apt upgrade -y
apt autoremove -y

# Install dependencies
echo "[INFO] Install dependencies"
sleep 2
apt install -y unzip make cmake jq git build-essential vnstat

# Get details
installIP=$(wget -qO- ipv4.icanhazip.com)
netInt=$(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}' | head -n 1 | awk '{print $1}')
clear
echo -e "\e[4mOrganization Info\e[0m"
read -p "Organization : " installOrg
read -p "Organization unit : " installOrgUnit
read -p "Country Code: " installCountry
read -p "Province : " installProvince
read -p "City : " installCity
echo ""
echo -e "\e[4mDNS Provider Info\e[0m"
echo "1 - Cloud Flare"
echo "2 - Digital Ocean"
until [ "$dnsChoice" = "1" ] || [ "$dnsChoice" = "2" ]; do
    read -p "Choose between 1 or 2: " dnsChoice
done
echo ""
if [ "$dnsChoice" = "1" ]; then
    installDNS="cf"
else
    installDNS="do"
fi
if [ "$installDNS" = "cf" ]; then
    read -p "CloudFlare API Token : " installCFToken
	if [[ $(curl -s -o /dev/null -w "%{http_code}" -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer $installCFToken") != "200" ]]; then
		echo "[ERROR] CLoudFlare token is not valid."
		read -n 1 -r -s -p $"Press any key to continue ... "
		exit 1
	fi
	domainList=($(curl -sX GET "https://api.cloudflare.com/client/v4/zones" -H "Authorization: Bearer $installCFToken" -H "Content-Type:application/json" | jq -r '.result[].name'))
	if [[ -z "$domainList" ]]; then
	echo "[ERROR] No domains found on Cloudflare."
	read -n 1 -r -s -p $"Press any key to continue ... "
	exit 1
	fi
	n=0
	echo ""
	for i in "${!domainList[@]}"; do
	echo "$((i+1)) - ${domainList[$i]}"
	done
	until [[ "$domainChoice" =~ ^[0-9]+$ && $domainChoice -ge 1 && $domainChoice -le ${#domainList[@]} ]]; do
		read -p "Choose your domain : " domainChoice
	done
	installDomain="${domainList[$((domainChoice-1))]}"
	read -p "Create a subdomain ( ??.${installDomain} ) : " sub
	installSubDomain="${sub}.${installDomain}"
	installEmail=$(curl -sX GET "https://api.cloudflare.com/client/v4/user" -H "Authorization: Bearer $installCFToken" -H "Content-Type:application/json" | jq -r '.result.email')
	if [[ $installEmail == "null" ]]; then
		echo ""
		read -p "Email : " installEmail
	fi
	zoneID=$(curl -sX GET "https://api.cloudflare.com/client/v4/zones?name=$installDomain" -H "Authorization: Bearer $installCFToken" -H "Content-Type:application/json" | jq -r '.result[0].id')
	echo ""
	id1=$(curl -sX GET "https://api.cloudflare.com/client/v4/zones/$zoneID/dns_records?type=A&name=$installSubDomain" -H "Authorization: Bearer $installCFToken" -H "Content-Type:application/json" | jq -r '.result[] | .id')
	id2=$(curl -sX GET "https://api.cloudflare.com/client/v4/zones/$zoneID/dns_records?type=A&name=*.$installSubDomain" -H "Authorization: Bearer $installCFToken" -H "Content-Type:application/json" | jq -r '.result[] | .id')
	id3=$(curl -sX GET "https://api.cloudflare.com/client/v4/zones/$zoneID/dns_records?type=NS&name=ns-$installSubDomain" -H "Authorization: Bearer $installCFToken" -H "Content-Type:application/json" | jq -r '.result[] | .id')
	if [[ -n "$id1" ]]; then
		echo "$installSubDomain exist. Updating ..."
		sleep 2
		for id in $id1; do
			curl -o /dev/null -sX DELETE "https://api.cloudflare.com/client/v4/zones/$zoneID/dns_records/$id" -H "Authorization: Bearer $installCFToken" -H "Content-Type:application/json"
		done
		curl -o /dev/null -sX POST "https://api.cloudflare.com/client/v4/zones/$zoneID/dns_records" -H "Authorization: Bearer $installCFToken" -H "Content-Type:application/json" --data "{\"type\":\"A\",\"name\":\"$installSubDomain\",\"content\":\"$installIP\",\"ttl\":1}"
	else
		echo "$installSubDomain not exist. Creating ..."
		sleep 2
		curl -o /dev/null -sX POST "https://api.cloudflare.com/client/v4/zones/$zoneID/dns_records" -H "Authorization: Bearer $installCFToken" -H "Content-Type:application/json" --data "{\"type\":\"A\",\"name\":\"$installSubDomain\",\"content\":\"$installIP\",\"ttl\":1}"
	fi
	if [[ -n "$id2" ]]; then
		echo "*.$installSubDomain exist. Updating ..."
		sleep 2
		for id in $id2; do
			curl -o /dev/null -sX DELETE "https://api.cloudflare.com/client/v4/zones/$zoneID/dns_records/$id" -H "Authorization: Bearer $installCFToken" -H "Content-Type:application/json"
		done
		curl -o /dev/null -sX POST "https://api.cloudflare.com/client/v4/zones/$zoneID/dns_records" -H "Authorization: Bearer $installCFToken" -H "Content-Type:application/json" --data "{\"type\":\"A\",\"name\":\"*.$installSubDomain\",\"content\":\"$installIP\",\"ttl\":1}"
	else
		echo "*.$installSubDomain not exist. Creating ..."
		sleep 2
		curl -o /dev/null -sX POST "https://api.cloudflare.com/client/v4/zones/$zoneID/dns_records" -H "Authorization: Bearer $installCFToken" -H "Content-Type:application/json" --data "{\"type\":\"A\",\"name\":\"*.$installSubDomain\",\"content\":\"$installIP\",\"ttl\":1}"
	fi
	if [[ -n "$id3" ]]; then
		echo "ns-$installSubDomain exist. Updating ..."
		sleep 2
		for id in $id3; do
			curl -o /dev/null -sX DELETE "https://api.cloudflare.com/client/v4/zones/$zoneID/dns_records/$id" -H "Authorization: Bearer $installCFToken" -H "Content-Type:application/json"
		done
		curl -o /dev/null -sX POST "https://api.cloudflare.com/client/v4/zones/$zoneID/dns_records" -H "Authorization: Bearer $installCFToken" -H "Content-Type:application/json" --data "{\"type\":\"NS\",\"name\":\"ns-$installSubDomain\",\"content\":\"$installSubDomain\",\"ttl\":1}"
	else
		echo "ns-$installSubDomain not exist. Creating ..."
		sleep 2
		curl -o /dev/null -sX POST "https://api.cloudflare.com/client/v4/zones/$zoneID/dns_records" -H "Authorization: Bearer $installCFToken" -H "Content-Type:application/json" --data "{\"type\":\"NS\",\"name\":\"ns-$installSubDomain\",\"content\":\"$installSubDomain\",\"ttl\":1}"
	fi
else
    read -p "DigitalOcean API Token : " installDOToken
	if [[ $(curl -s -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" -H "Authorization: Bearer $installDOToken" "https://api.digitalocean.com/v2/account") != "200" ]]; then
		echo "[ERROR] DigitalOcean token is not valid."
		read -n 1 -r -s -p $"Press any key to continue ... "
		exit 1
	fi
	domainList=($(curl -sX GET -H "Content-Type: application/json" -H "Authorization: Bearer $installDOToken" "https://api.digitalocean.com/v2/domains" | jq -r '.domains[].name'))
	if [[ -z "$domainList" ]]; then
	echo "[ERROR] No domains found on DigitalOcean."
	read -n 1 -r -s -p $"Press any key to continue ... "
	exit 1
	fi
	n=0
	echo ""
	for i in "${!domainList[@]}"; do
	echo "$((i+1)) - ${domainList[$i]}"
	done
	until [[ "$domainChoice" =~ ^[0-9]+$ && $domainChoice -ge 1 && $domainChoice -le ${#domainList[@]} ]]; do
		read -p "Choose your domain : " domainChoice
	done
	installDomain="${domainList[$((domainChoice-1))]}"
	read -p "Create a subdomain ( ??.${installDomain} ) : " sub
	installSubDomain="${sub}.${installDomain}"
	installEmail=$(curl -s -H "Content-Type: application/json" -H "Authorization: Bearer $installDOToken" "https://api.digitalocean.com/v2/account" | jq -r '.account.email')
	if [[ -z "$installEmail" ]]; then
		echo ""
		read -p "Email : " installEmail
		echo ""
	fi
	id1=$(curl -s -H "Content-Type: application/json" -H "Authorization: Bearer $installDOToken" "https://api.digitalocean.com/v2/domains/$installDomain/records" | jq -r ".domain_records[] | select(.name == \"$sub\" and .type == \"A\") | .id")
	id2=$(curl -s -H "Content-Type: application/json" -H "Authorization: Bearer $installDOToken" "https://api.digitalocean.com/v2/domains/$installDomain/records" | jq -r ".domain_records[] | select(.name == \"*.$sub\" and .type == \"A\") | .id")
	id3=$(curl -s -H "Content-Type: application/json" -H "Authorization: Bearer $installDOToken" "https://api.digitalocean.com/v2/domains/$installDomain/records" | jq -r ".domain_records[] | select(.name == \"ns-$sub\" and .type == \"NS\") | .id")
	echo ""
	if [[ -n "$id1" ]]; then
		echo "$installSubDomain exist. Updating ..."
		sleep 2
		for id in $id1; do
			curl -o /dev/null -sX DELETE -H "Content-Type: application/json" -H "Authorization: Bearer $installDOToken" "https://api.digitalocean.com/v2/domains/$installDomain/records/$id"
		done
		curl -o /dev/null -sX POST -H "Content-Type: application/json" -H "Authorization: Bearer $installDOToken" -d "{\"type\":\"A\",\"name\":\"$sub\",\"data\":\"$installIP\"}" "https://api.digitalocean.com/v2/domains/$installDomain/records"
	else
		echo "$installSubDomain not exist. Creating ..."
		sleep 2
		curl -o /dev/null -sX POST -H "Content-Type: application/json" -H "Authorization: Bearer $installDOToken" -d "{\"type\":\"A\",\"name\":\"$sub\",\"data\":\"$installIP\"}" "https://api.digitalocean.com/v2/domains/$installDomain/records"
	fi
	if [[ -n "$id2" ]]; then
		echo "*.$installSubDomain exist. Updating ..."
		sleep 2
		for id in $id2; do
			curl -o /dev/null -sX DELETE -H "Content-Type: application/json" -H "Authorization: Bearer $installDOToken" "https://api.digitalocean.com/v2/domains/$installDomain/records/$id"
		done
		curl -o /dev/null -sX POST -H "Content-Type: application/json" -H "Authorization: Bearer $installDOToken" -d "{\"type\":\"A\",\"name\":\"*.$sub\",\"data\":\"$installIP\"}" "https://api.digitalocean.com/v2/domains/$installDomain/records"
	else
		echo "*.$installSubDomain not exist. Creating ..."
		sleep 2
		curl -o /dev/null -sX POST -H "Content-Type: application/json" -H "Authorization: Bearer $installDOToken" -d "{\"type\":\"A\",\"name\":\"*.$sub\",\"data\":\"$installIP\"}" "https://api.digitalocean.com/v2/domains/$installDomain/records"
	fi
	if [[ -n "$id3" ]]; then
		echo "ns-$installSubDomain exist. Updating ..."
		sleep 2
		for id in $id3; do
			curl -o /dev/null -sX DELETE -H "Content-Type: application/json" -H "Authorization: Bearer $installDOToken" "https://api.digitalocean.com/v2/domains/$installDomain/records/$id"
		done
		curl -o /dev/null -sX POST -H "Content-Type: application/json" -H "Authorization: Bearer $installDOToken" -d "{\"type\":\"NS\",\"name\":\"ns-$sub\",\"data\":\"$installSubDomain.\"}" "https://api.digitalocean.com/v2/domains/$installDomain/records"
	else
		echo "ns-$installSubDomain not exist. Creating ..."
		sleep 2
		curl -o /dev/null -sX POST -H "Content-Type: application/json" -H "Authorization: Bearer $installDOToken" -d "{\"type\":\"NS\",\"name\":\"ns-$sub\",\"data\":\"$installSubDomain.\"}" "https://api.digitalocean.com/v2/domains/$installDomain/records"
	fi
fi

echo ""
echo "[INFO] Starting installation ..."
sleep 5
clear

# Disable IPv6
echo "[INFO] Disable IPv6"
sleep 2
echo "# Disable IPv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1" > /etc/sysctl.d/kamui.conf
sysctl -p /etc/sysctl.d/kamui.conf

# Enable BBR
echo "[INFO] Enable BBR"
sleep 2
echo -e "\n# Enable BBR Congestion Control
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.d/kamui.conf
sysctl -p /etc/sysctl.d/kamui.conf

# Set DNS
echo "[INFO] Set DNS"
sleep 2
apt install -y resolvconf
echo "nameserver 8.8.8.8" >> /etc/resolvconf/resolv.conf.d/head
echo "nameserver 8.8.4.4" >> /etc/resolvconf/resolv.conf.d/head
resolvconf --enable-updates
resolvconf -u

# Change timezone to Asia/Kuala_Lumpur (GMT +8)
echo "[INFO] Change timezone to Asia/Kuala_Lumpur (GMT +8)"
sleep 2
timedatectl set-timezone Asia/Kuala_Lumpur

# Reset iptables
echo "[INFO] Reset iptables"
sleep 2
systemctl stop firewalld
systemctl disable firewalld
systemctl stop nftables
systemctl disable nftables
systemctl stop ufw
systemctl disable ufw
apt install -y iptables-persistent
iptables-save | awk '/^[*]/ { print $1 }
                     /^:[A-Z]+ [^-]/ { print $1 " ACCEPT" ; }
                     /COMMIT/ { print $0; }' | iptables-restore

# Create script directory
echo "[INFO] Create script directory"
sleep 2
mkdir /kamui

# Configure SSH
echo "[INFO] Configure SSH"
sleep 2
echo ".: $installOrg :." > /etc/issue.net
sed -i "s/#Banner none/Banner \/etc\/issue.net/g" /etc/ssh/sshd_config
echo "AllowUsers root" >> /etc/ssh/sshd_config
systemctl restart ssh

# Install Dropbear
echo "[INFO] Install Dropbear"
sleep 2
apt install -y libz-dev gcc
git clone https://github.com/mkj/dropbear.git
cd dropbear
./configure
make
make install
cd
rm -rf dropbear
echo "/bin/false" >> /etc/shells
echo ".: $installOrg :." > /etc/db-issue.net
mkdir /etc/dropbear
dropbear -Rw -p 85 -b /etc/db-issue.net

# Install dnstt-server
echo "[INFO] Install dnstt-server"
sleep 2
wget -O go.tar.gz "${linkGo}"
tar -xzf go.tar.gz -C /usr/local
rm -f go.tar.gz
echo -e "\n# GO path
export PATH=/usr/local/go/bin:${PATH}" | tee -a $HOME/.profile
source $HOME/.profile
git clone https://www.bamsoftware.com/git/dnstt.git
cd dnstt/dnstt-server
go build
cp dnstt-server /usr/bin/dnstt-server
chmod +x /usr/bin/dnstt-server
cd
rm -rf dnstt
mkdir /kamui/dnstt
dnstt-server -gen-key -privkey-file /kamui/dnstt/server.key -pubkey-file /kamui/dnstt/server.pub
iptables -I INPUT -p udp --dport 5300 -j ACCEPT
iptables -t nat -I PREROUTING -i $netInt -p udp --dport 53 -j REDIRECT --to-ports 5300
ip6tables -I INPUT -p udp --dport 5300 -j ACCEPT
ip6tables -t nat -I PREROUTING -i $netInt -p udp --dport 53 -j REDIRECT --to-ports 5300
screen -AmdS dnstt dnstt-server -udp :5300 -privkey-file /kamui/dnstt/server.key ns-${installSubDomain} 127.0.0.1:85

# Install UDP Custom (https://t.me/ePro_Dev_Team)
mkdir /kamui/udp-custom
wget -O /kamui/udp-custom/udp-custom "${repoDir}files/udp-custom/udp-custom"
wget -O /kamui/udp-custom/config.json "${repoDir}files/udp-custom/config.json"
chmod +x /kamui/udp-custom/udp-custom
screen -AmdS udp-custom bash -c 'cd /kamui/udp-custom/ && ./udp-custom server -exclude 7300,53,5300,1194,51820'

# Install OpenVPN
echo "[INFO] Install OpenVPN"
sleep 2
curl -fsSL https://swupdate.openvpn.net/repos/repo-public.gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/openvpn-public-repo.gpg
echo "# OpenVPN Public Repo
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/openvpn-public-repo.gpg] https://build.openvpn.net/debian/openvpn/stable ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/kamui.list
apt update
apt install -y openvpn
apt remove -y easy-rsa
apt autoremove -y
wget -O EasyRSA.tgz "${linkEasyRSA}"
tar -xzf EasyRSA.tgz
rm -f EasyRSA.tgz
mv $(ls -d */ | cut -f1 -d '/' | grep EasyRSA) /etc/openvpn/easy-rsa
cp /etc/openvpn/easy-rsa/vars.example /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_COUNTRY\t"US"/set_var EASYRSA_REQ_COUNTRY\t"'"${installCountry}"'"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_PROVINCE\t"California"/set_var EASYRSA_REQ_PROVINCE\t"'"${installProvince}"'"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_CITY\t"San Francisco"/set_var EASYRSA_REQ_CITY\t"'"${installCity}"'"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_ORG\t"Copyleft Certificate Co"/set_var EASYRSA_REQ_ORG\t\t"'"${installOrg}"'"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_EMAIL\t"me@example.net"/set_var EASYRSA_REQ_EMAIL\t"'"${installEmail}"'"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_OU\t\t"My Organizational Unit"/set_var EASYRSA_REQ_OU\t\t"'"${installOrgUnit}"'"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_CA_EXPIRE\t3650/set_var EASYRSA_CA_EXPIRE\t3650/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_CERT_EXPIRE\t825/set_var EASYRSA_CERT_EXPIRE\t3650/g' /etc/openvpn/easy-rsa/vars
cd /etc/openvpn/easy-rsa
./easyrsa --batch init-pki
./easyrsa --batch build-ca nopass
./easyrsa gen-dh
./easyrsa --batch build-server-full server nopass
cd
mkdir /etc/openvpn/key
cp /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn/key/
cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/key/
cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn/key/
cp /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn/key/
wget -O /etc/openvpn/udp.conf "${repoDir}files/openvpn/server-udp.conf"
wget -O /etc/openvpn/tcp.conf "${repoDir}files/openvpn/server-tcp.conf"
sed -i "s/#AUTOSTART="all"/AUTOSTART="all"/g" /etc/default/openvpn
echo -e "\n# IPv4 forwarding
net.ipv4.ip_forward = 1" >> /etc/sysctl.d/kamui.conf
sysctl -p /etc/sysctl.d/kamui.conf
iptables -t nat -I POSTROUTING -s 10.8.0.0/24 -o ${netInt} -j MASQUERADE
iptables -t nat -I POSTROUTING -s 10.9.0.0/24 -o ${netInt} -j MASQUERADE
systemctl start openvpn@udp
systemctl start openvpn@tcp
systemctl enable openvpn@udp
systemctl enable openvpn@tcp

# Configure OpenVPN client configuration
echo "[INFO] Configure OpenVPN client configuration"
sleep 2
mkdir /kamui/openvpn
wget -O /kamui/openvpn/udp.ovpn "${repoDir}files/openvpn/client-udp.ovpn"
wget -O /kamui/openvpn/tcp.ovpn "${repoDir}files/openvpn/client-tcp.ovpn"
sed -i "s/install_ip/$installIP/g" /kamui/openvpn/udp.ovpn
sed -i "s/install_ip/$installIP/g" /kamui/openvpn/tcp.ovpn
echo -e "\n<ca>" >> /kamui/openvpn/udp.ovpn
cat "/etc/openvpn/key/ca.crt" >> /kamui/openvpn/udp.ovpn
echo "</ca>" >> /kamui/openvpn/udp.ovpn
echo -e "\n<ca>" >> /kamui/openvpn/tcp.ovpn
cat "/etc/openvpn/key/ca.crt" >> /kamui/openvpn/tcp.ovpn
echo "</ca>" >> /kamui/openvpn/tcp.ovpn

# Install Squid Proxy
echo "[INFO] Install Squid Proxy"
sleep 2
apt install -y squid
wget -O /etc/squid/squid.conf "${repoDir}files/others/squid.conf"
sed -i "s/install_ip/$installIP/g" /etc/squid/squid.conf
sed -i "s/install_domain/$installSubDomain/g" /etc/squid/squid.conf
systemctl restart squid

# Install Python Proxy (WebSocket)
echo "[INFO] Install Python Proxy (WebSocket)"
sleep 2
wget -O python.tgz "${repoDir}files/others/Python-2.7.18.tgz"
tar -xzf python.tgz
rm -f python.tgz
cd Python-2.7.18
./configure
make
make install
cd
rm -rf Python-2.7.18
mkdir /kamui/websocket
wget -O /kamui/websocket/ws-dropbear.py "${repoDir}files/websocket/ws-dropbear.py"
wget -O /kamui/websocket/ws-openvpn.py "${repoDir}files/websocket/ws-openvpn.py"
wget -O /kamui/websocket/ohpserver "${repoDir}files/websocket/ohpserver"
chmod +x /kamui/websocket/ohpserver
screen -AmdS ohp-dropbear /kamui/websocket/ohpserver -port 3128 -proxy 127.0.0.1:8080 -tunnel 127.0.0.1:85
screen -AmdS ohp-openvpn /kamui/websocket/ohpserver -port 8000 -proxy 127.0.0.1:8080 -tunnel 127.0.0.1:194
screen -AmdS ws-dropbear python2 /kamui/websocket/ws-dropbear.py
screen -AmdS ws-openvpn python2 /kamui/websocket/ws-openvpn.py

# Install BadVPN UDPGw
echo "[INFO] Install BadVPN UDPGw"
sleep 2
git clone https://github.com/ambrop72/badvpn.git
mkdir badvpn/build-badvpn
cd badvpn/build-badvpn
cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
make install
cd
rm -rf badvpn
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

# Install WireGuard
echo "[INFO] Install WireGuard"
sleep 2
apt install -y wireguard qrencode
server_priv_key=$(wg genkey)
server_pub_key=$(echo "${server_priv_key}" | wg pubkey)
echo "ip=${installIP}
server_priv_key=${server_priv_key}
server_pub_key=${server_pub_key}
endpoint=${installIP}:51820" > /etc/wireguard/params
source /etc/wireguard/params
echo "[Interface]
Address = 10.66.66.1/24
ListenPort = 51820
PrivateKey = ${server_priv_key}
PostUp = sleep 1; iptables -A FORWARD -i ${netInt} -o wg0 -j ACCEPT; iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ${netInt} -j MASQUERADE
PostDown = iptables -D FORWARD -i ${netInt} -o wg0 -j ACCEPT; iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ${netInt} -j MASQUERADE" >> /etc/wireguard/wg0.conf
systemctl start wg-quick@wg0
systemctl enable wg-quick@wg0
mkdir /kamui/wireguard

# Install Xray Core
echo "[INFO] Install Xray Core"
sleep 2
mkdir /kamui/xray
apt install -y snapd apache2-utils
snap install core
snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
snap set certbot trust-plugin-with-root=ok
if [ "$installDNS" = "cf" ]; then
    snap install certbot-dns-cloudflare
	echo "# Cloudflare API token used by Certbot
	dns_cloudflare_api_token =  ${installCFToken}" > /kamui/xray/cloudflare.ini
	chmod 600 /kamui/xray/cloudflare.ini
	certbot certonly --dns-cloudflare --dns-cloudflare-credentials /kamui/xray/cloudflare.ini --dns-cloudflare-propagation-seconds 30 --noninteractive --agree-tos -d $installSubDomain -d *.$installSubDomain --register-unsafely-without-email
else
    snap install certbot-dns-digitalocean
	echo "# DigitalOcean API token used by Certbot
	dns_digitalocean_token = ${installDOToken}" > /kamui/xray/digitalocean.ini
	chmod 600 /kamui/xray/digitalocean.ini
	certbot certonly --dns-digitalocean --dns-digitalocean-credentials /kamui/xray/digitalocean.ini --dns-digitalocean-propagation-seconds 30 --noninteractive --agree-tos -d $installSubDomain -d *.$installSubDomain --register-unsafely-without-email
fi
chmod -R 755 /etc/letsencrypt/live/
chmod -R 755 /etc/letsencrypt/archive/
bash -c "$(curl -sL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor > /etc/apt/trusted.gpg.d/nginx-official-repo.gpg
echo "# Nginx Official Repo
deb [signed-by=/etc/apt/trusted.gpg.d/nginx-official-repo.gpg] http://nginx.org/packages/debian ${VERSION_CODENAME} nginx" >> /etc/apt/sources.list.d/kamui.list
apt update
apt install -y nginx
rm -f /etc/nginx/conf.d/*
rm -rf /var/www/html
mkdir -p /var/www/html
wget -O web.zip "${repoDir}files/xray/web.zip"
unzip web.zip -d /var/www/html/
rm -f web.zip
sed -i "s/install_org/${installOrg}/g" /var/www/html/index.html
find /var/www/html/ -type d -exec chmod 750 {} \;
find /var/www/html/ -type f -exec chmod 640 {} \;
chown -R nginx:nginx /var/www/html
wget -O /etc/nginx/conf.d/${installSubDomain}.conf "${repoDir}files/xray/web.conf"
htpasswd -bc /etc/nginx/conf.d/.htpasswd kamui P4s5W0rD
wget -O /usr/local/etc/xray/tls.json "${repoDir}files/xray/tls.json"
wget -O /usr/local/etc/xray/ntls.json "${repoDir}files/xray/ntls.json"
sed -i "s/install_domain/${installSubDomain}/g" /usr/local/etc/xray/tls.json
sed -i "s/install_domain/${installSubDomain}/g" /usr/local/etc/xray/ntls.json
sed -i "s/install_domain/${installSubDomain}/g" /etc/nginx/conf.d/${installSubDomain}.conf
sed -i "s/cert_path/\/etc\/letsencrypt\/live\/${installSubDomain}\/fullchain.pem/g" /usr/local/etc/xray/tls.json
sed -i "s/key_path/\/etc\/letsencrypt\/live\/${installSubDomain}\/privkey.pem/g" /usr/local/etc/xray/tls.json
mkdir /etc/systemd/system/nginx.service.d
echo -e "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
systemctl daemon-reload
systemctl restart nginx
systemctl start xray@tls
systemctl start xray@ntls
systemctl enable xray@tls
systemctl enable xray@ntls

# Install stunnel
echo "[INFO] Install stunnel"
sleep 2
apt install -y libssl-dev
wget -O stunnel.tar.gz "${linkStunnel}"
tar -xzf stunnel.tar.gz
rm -f stunnel.tar.gz
cd $(ls -d */ | cut -f1 -d '/' | grep stunnel)
./configure
make
make install
cd
rm -rf $(ls -d */ | cut -f1 -d '/' | grep stunnel)
wget -O /usr/local/etc/stunnel/stunnel.conf "${repoDir}files/others/stunnel.conf"
sed -i "s/cert_path/\/etc\/letsencrypt\/live\/${installSubDomain}\/fullchain.pem/g" /usr/local/etc/stunnel/stunnel.conf
sed -i "s/key_path/\/etc\/letsencrypt\/live\/${installSubDomain}\/privkey.pem/g" /usr/local/etc/stunnel/stunnel.conf
stunnel /usr/local/etc/stunnel/stunnel.conf

# Install Speedtest CLI
echo "[INFO] Install Speedtest CLI"
sleep 2
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
apt install -y speedtest

# Install Fail2Ban
echo "[INFO] Install Fail2Ban"
sleep 2
apt install -y python3 python3-setuptools
git clone https://github.com/fail2ban/fail2ban.git
cd fail2ban
python3 setup.py install
cp files/debian-initd /etc/init.d/fail2ban
cd
rm -rf fail2ban
update-rc.d fail2ban defaults
service fail2ban start

# Install DDoS Deflate
echo "[INFO] Install DDoS Deflate"
sleep 2
apt install -y dnsutils tcpdump dsniff grepcidr net-tools
wget -O ddos.zip "${repoDir}files/others/ddos-deflate.zip"
unzip ddos.zip
cd ddos-deflate
chmod +x install.sh
./install.sh
cd
rm -rf ddos.zip ddos-deflate

# Save iptables
echo "[INFO] Save iptables"
sleep 2
systemctl stop wg-quick@wg0
iptables-save > /kamui/iptables.rules
systemctl start wg-quick@wg0

# Save install parameters
echo "[INFO] Save install parameters"
sleep 2
echo -e "repoDir=\"${repoDir}\"
installEmail=\"${installEmail}\"
installOrg=\"${installOrg}\"
installOrgUnit=\"${installOrgUnit}\"
installCountry=\"${installCountry}\"
installProvince=\"${installProvince}\"
installCity=\"${installCity}\"
installDNS=\"${installDNS}\"
installDomain=\"${installDomain}\"
installSubDomain=\"${installSubDomain}\"
installIP=\"${installIP}\"
netInt=\"${netInt}\"" > /kamui/params

# Configure menu
echo "[INFO] Configure menu"
sleep 2
mkdir /kamui/log
mkdir -p /kamui/menu/{ssh,wireguard,xray,other}
wget -O /kamui/menu/ssh/add.sh "${repoDir}files/menu/ssh/add.sh"
wget -O /kamui/menu/ssh/delete.sh "${repoDir}files/menu/ssh/delete.sh"
wget -O /kamui/menu/ssh/extend.sh "${repoDir}files/menu/ssh/extend.sh"
wget -O /kamui/menu/ssh/list.sh "${repoDir}files/menu/ssh/list.sh"
wget -O /kamui/menu/ssh/detail.sh "${repoDir}files/menu/ssh/detail.sh"
wget -O /kamui/menu/ssh/dropbear_monitor.sh "${repoDir}files/menu/ssh/dropbear_monitor.sh"
wget -O /kamui/menu/ssh/openvpn_monitor.sh "${repoDir}files/menu/ssh/openvpn_monitor.sh"
wget -O /kamui/menu/wireguard/add.sh "${repoDir}files/menu/wireguard/add.sh"
wget -O /kamui/menu/wireguard/delete.sh "${repoDir}files/menu/wireguard/delete.sh"
wget -O /kamui/menu/wireguard/extend.sh "${repoDir}files/menu/wireguard/extend.sh"
wget -O /kamui/menu/wireguard/list.sh "${repoDir}files/menu/wireguard/list.sh"
wget -O /kamui/menu/wireguard/detail.sh "${repoDir}files/menu/wireguard/detail.sh"
wget -O /kamui/menu/xray/trojan_add.sh "${repoDir}files/menu/xray/trojan_add.sh"
wget -O /kamui/menu/xray/trojan_delete.sh "${repoDir}files/menu/xray/trojan_delete.sh"
wget -O /kamui/menu/xray/trojan_extend.sh "${repoDir}files/menu/xray/trojan_extend.sh"
wget -O /kamui/menu/xray/trojan_detail.sh "${repoDir}files/menu/xray/trojan_detail.sh"
wget -O /kamui/menu/xray/trojan_list.sh "${repoDir}files/menu/xray/trojan_list.sh"
wget -O /kamui/menu/xray/trojan_monitor.sh "${repoDir}files/menu/xray/trojan_monitor.sh"
wget -O /kamui/menu/xray/vless_add.sh "${repoDir}files/menu/xray/vless_add.sh"
wget -O /kamui/menu/xray/vless_delete.sh "${repoDir}files/menu/xray/vless_delete.sh"
wget -O /kamui/menu/xray/vless_extend.sh "${repoDir}files/menu/xray/vless_extend.sh"
wget -O /kamui/menu/xray/vless_detail.sh "${repoDir}files/menu/xray/vless_detail.sh"
wget -O /kamui/menu/xray/vless_list.sh "${repoDir}files/menu/xray/vless_list.sh"
wget -O /kamui/menu/xray/vless_monitor.sh "${repoDir}files/menu/xray/vless_monitor.sh"
wget -O /kamui/menu/xray/vmess_add.sh "${repoDir}files/menu/xray/vmess_add.sh"
wget -O /kamui/menu/xray/vmess_delete.sh "${repoDir}files/menu/xray/vmess_delete.sh"
wget -O /kamui/menu/xray/vmess_extend.sh "${repoDir}files/menu/xray/vmess_extend.sh"
wget -O /kamui/menu/xray/vmess_detail.sh "${repoDir}files/menu/xray/vmess_detail.sh"
wget -O /kamui/menu/xray/vmess_list.sh "${repoDir}files/menu/xray/vmess_list.sh"
wget -O /kamui/menu/xray/vmess_monitor.sh "${repoDir}files/menu/xray/vmess_monitor.sh"
wget -O /kamui/menu/other/check.sh "${repoDir}files/menu/other/check.sh"
wget -O /kamui/menu/other/update_script.sh "${repoDir}files/menu/other/update_script.sh"
wget -O /kamui/menu/other/update_package.sh "${repoDir}files/menu/other/update_package.sh"
wget -O /kamui/menu/other/web_login.sh "${repoDir}files/menu/other/web_login.sh"
find /kamui/menu/ -type f -exec chmod +x {} \;
wget -O /usr/bin/menu "${repoDir}files/menu/menu.sh"
chmod +x /usr/bin/menu

# Add user_database.json
echo "[INFO] Add user_database.json"
sleep 2
echo "{
    \"ssh\": [],
    \"xray\": {
        \"vless\": [],
        \"vmess\": [],
        \"trojan\": []
    },
    \"wireguard\" : []
}" > /kamui/user_database.json

# Configure cron
echo "[INFO] Configure cron"
sleep 2
mkdir /kamui/cron
wget -O /kamui/cron/reboot.sh "${repoDir}files/cron/reboot.sh"
wget -O /kamui/cron/hourly.sh "${repoDir}files/cron/hourly.sh"
wget -O /kamui/cron/midnight.sh "${repoDir}files/cron/midnight.sh"
sed -i "s/install_domain/${installSubDomain}/g" /kamui/cron/reboot.sh
find /kamui/cron/ -type f -exec chmod +x {} \;
(crontab -l; echo "@reboot /kamui/cron/reboot.sh") | crontab -
(crontab -l; echo "@hourly /kamui/cron/hourly.sh") | crontab -
(crontab -l; echo "@midnight /kamui/cron/midnight.sh") | crontab -
(crontab -l; echo "0 4 * * * /sbin/reboot") | crontab -

# Configure neofetch
echo "[INFO] Configure neofetch"
sleep 2
apt install -y neofetch
echo -e "\n# Print system information on login\nclear\nneofetch" >> .profile

# Cleanup
echo "[INFO] Cleanup"
sleep 2
rm -f install.sh
cat /dev/null > ~/.bash_history
echo "clear
cat /dev/null > ~/.bash_history
history -c" >> ~/.bash_logout
reboot
