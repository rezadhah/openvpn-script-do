# OpenVPN Script

This script is based on [here](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-ubuntu-16-04)

## How to use :
```sh
$ ./create_server # wait until finish
$ ./create_client user1 # you can change user1
```

# How to get the credentials to root folder :
```sh
$ scp $cwd/client-configs-{your-username}/files/{your-username}.ovpn {your-host}
```
