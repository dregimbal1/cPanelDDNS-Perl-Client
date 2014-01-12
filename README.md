cPanel Update IP
================

Description
-----------

This plugin will login into cPanel and update the A record of the specified domain/subdomain to the machine that's running this script, making it act like a DDNS.

Instruction
-----------

The script is by mean to run on a cronjob. But if you want to manually run the script, you can just call `perl cpanel_update_ip.pl` in the command line.

Changelog
---------

v1.0.0

- Initial release
