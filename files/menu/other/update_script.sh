#!/bin/bash

source /kamui/params

clear
echo ""
echo -e "\e[4mScripts Updater\e[24m"
echo ""
echo "This script will update current installed scripts with the latest version."
echo ""
read -p "Do you want to continue (y/n) ? " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "[INFO] Operation aborted"
    echo ""
    read -n 1 -r -s -p $"Press any key to continue ... "
    exit 0
fi
clear
echo -e "[INFO] Update scripts\n"
sleep 2
cat << \EOF > /tmp/update_script.sh
#!/bin/bash

source /kamui/params

screen -XS multilogin quit
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
rm -f /tmp/update_script.sh
echo -e "\n[INFO] Scripts updated successfully\n"
read -n 1 -r -s -p $"Press any key to continue ... "
EOF
chmod +x /tmp/update_script.sh
(/tmp/update_script.sh)
