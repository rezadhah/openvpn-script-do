#!/bin/bash

cwd=$PWD
rm -rf client-configs-*
rm -rf *.ovpn
rm -rf openvpn-ca

sudo apt-get remove -y ufw && sudo apt-get purge -y ufw
sudo apt-get remove -y openvpn && sudo apt-get purge -y openvpn
sudo rm -rf /etc/openvpn

killall openvpn
apt-get update && apt-get -y install openvpn easy-rsa ufw vnstat

echo "create ca directory..."
make-cadir $cwd/openvpn-ca

echo "build ca certificates..."
cd $cwd/openvpn-ca
sed -i -e 's/export KEY_COUNTRY="me@myhost.mydomain"/export KEY_EMAIL="admin@example.com"/g' vars
sed -i -e 's/export KEY_EMAIL="me@myhost.mydomain"/export KEY_EMAIL="admin@example.com"/g' vars
sed -i -e 's/export KEY_ORG="Fort-Funston"/export KEY_ORG="DigitalOcean"/g' vars
sed -i -e 's/export KEY_OU="MyOrganizationalUnit"/export KEY_OU="Community"/g' vars
sed -i -e 's/export KEY_NAME="EasyRSA"/export KEY_NAME="server"/g' vars
source vars
./clean-all
./build-ca --batch
echo "build server certificate, key, encryptiion files..."
./build-key-server --batch server
./build-dh
openvpn --genkey --secret keys/ta.key
source vars

echo "configure openvpn service..."
cd $cwd/openvpn-ca/keys
sudo cp ca.crt server.crt server.key ta.key dh2048.pem /etc/openvpn
gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | sudo tee /etc/openvpn/server.conf

# edit /etc/openvpn/server.conf
echo "auth SHA256" >> /etc/openvpn/server.conf
echo "key-direction 0" >> /etc/openvpn/server.conf
# echo "rcvbuf 0" >> /etc/openvpn/server.conf
# echo "sndbuf 0" >> /etc/openvpn/server.conf
# sed -i -e 's/comp-lzo/# comp-lzo/g' /etc/openvpn/server.conf

sed -i -e 's/;tls-auth ta.key 0/tls-auth ta.key 0/g' /etc/openvpn/server.conf
sed -i -e 's/;cipher AES-128-CBC/cipher AES-128-CBC/g' /etc/openvpn/server.conf
sed -i -e 's/;user nobody/user nobody/g' /etc/openvpn/server.conf
sed -i -e 's/;group nogroup/group nogroup/g' /etc/openvpn/server.conf
sed -i -e 's/;push "redirect-gateway def1 bypass-dhcp"/push "redirect-gateway def1 bypass-dhcp"/g' /etc/openvpn/server.conf
sed -i -e 's/;push "dhcp-option DNS 208.67.222.222"/push "dhcp-option DNS 8.8.8.8"/g' /etc/openvpn/server.conf
sed -i -e 's/;push "dhcp-option DNS 208.67.220.220"/push "dhcp-option DNS 8.8.4.4"/g' /etc/openvpn/server.conf
sed -i -e 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
# sed -i -e 's/;topology subnet/topology subnet/g' /etc/openvpn/server.conf

interface=$(ip route | grep default | awk '{print $5}')
echo "# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0] 
-A POSTROUTING -s 10.8.0.0/8 -o $interface -j MASQUERADE
COMMIT
# END OPENVPN RULES" >> /etc/ufw/before.rules
sed -i -e 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw
sudo ufw allow 1194/udp
sudo ufw allow OpenSSH
sudo ufw disable
yes "y" | sudo ufw enable
sudo systemctl start openvpn@server
sudo systemctl enable openvpn@server
