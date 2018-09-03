#!/bin/bash

cwd=$PWD
IS_WINDOWS=0

if [ $# -eq 0 ]; then
  echo "Please input user name (without space) in argument"
  echo "Example: ./create_client.sh patrick_star"
  exit 1
fi

rm -rf $cwd/client-configs-${1}
mkdir -p $cwd/client-configs-${1}/files
chmod 700 $cwd/client-configs-${1}/files

read -p "Is this for windows user? [Y/N]" answer
  case $answer in
    y|Y)
      IS_WINDOWS=1
      break
    ;;
    n|N)
      break
      ;;
    *)
      echo "Exiting script for invalid answer ... "
      exit
      ;;
esac

# this is the step for creating client key
# if you want to create user with pass, use ./build-key-pass
echo "generate client certificate..."
cd $cwd/openvpn-ca
source vars
./build-key --batch ${1}

cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf $cwd/client-configs-${1}/base.conf

ip=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
sed -i -e 's/remote my-server-1 1194/remote '"$ip"' 1194/g' $cwd/client-configs-${1}/base.conf
sed -i -e 's/ca ca.crt/# ca ca.crt/g' $cwd/client-configs-${1}/base.conf
sed -i -e 's/cert client.crt/# cert client.crt/g' $cwd/client-configs-${1}/base.conf
sed -i -e 's/key client.key/# key client.key/g' $cwd/client-configs-${1}/base.conf
sed -i -e 's/comp-lzo /;comp-lzo/g' $cwd/client-configs-${1}/base.conf
echo "cipher AES-128-CBC" >> $cwd/client-configs-${1}/base.conf
echo "auth SHA256" >> $cwd/client-configs-${1}/base.conf
echo "key-direction 1" >> $cwd/client-configs-${1}/base.conf
echo "rcvbuf 0" >> $cwd/client-configs-${1}/base.conf
echo "sndbuf 0" >> $cwd/client-configs-${1}/base.conf
# echo "setenv opt block-outside-dns" >> $cwd/client-configs-${1}/base.conf
# sed -i -e 's/comp-lzo /;comp-lzo/g' $cwd/client-configs-${1}/base.conf

echo "IS_WINDOWS == $IS_WINDOWS"
if [ $IS_WINDOWS -eq 0 ]; then
  sed -i -e 's/;user nobody/user nobody/g' $cwd/client-configs-${1}/base.conf
  sed -i -e 's/;group nogroup/group nogroup/g' $cwd/client-configs-${1}/base.conf
	echo "script-security 2" >> $cwd/client-configs-${1}/base.conf
	echo "up /etc/openvpn/update-resolv-conf" >> $cwd/client-configs-${1}/base.conf
	echo "down /etc/openvpn/update-resolv-conf" >> $cwd/client-configs-${1}/base.conf
fi

cd $cwd
./make_config.sh ${1}
cp $cwd/client-configs-${1}/files/${1}.ovpn $cwd
