#!/bin/bash

mkdir -p /var/log/dnsbl-ipset
touch /var/log/iptables-audit.log /var/log/dnsbl-ipset/blacklist.log
chmod 666 /var/log/iptables-audit.log

if [ -f /srv/scripts/logrotate.sh ]; then
	/srv/scripts/logrotate.sh /var/log/dnsbl-ipset/
	/srv/scripts/logrotate.sh /var/log/iptables-audit.log
fi

tail -F /var/log/dnsbl-ipset/blacklist.log &


