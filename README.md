# cPanel Dynamic DNS Client
Just like NO-IP you can use this script on your local machine and when your public IP address changes it will reflect in your A record within cPanel. You do not need root access to the server to run this script. Supports updating the A Record to multiple domain names.
### Fully Functional!
Updated to the latest cPanel API 2 URI calls this script will run as much as you like and it will keep track of your public IP and update it accordingly. Once your IP does change this script will remove the old A Record prior to adding the new one. It is self-sufficent. Please star / follow if you find this useful.
### Version
0.0.1
### Installation
  - Download and unzip
  - Modify config.cPanelDDNS.txt (example provided)
	- 1 account per line in the format [cpanel url omit port number] [subdomain] [domain] [username] [password]
```sh
$ perl cpanel_update_ip.pl
```
License
----
Forked from https://github.com/hwa107/cpanel-update-ip

GNU GENERAL PUBLIC LICENSE

Changelog
----
0.0.1
  - Support for multiple domain names
  - Updated to latest cPanel API 2 URI
