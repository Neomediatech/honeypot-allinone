#!/bin/bash

set -e

DEBUG="${DEBUG:-}"
[ "$DEBUG" == 'true' ] && set -x

STDOUT_LOGGING="${STDOUT_LOGGING:-false}"

[ ! -d /data/dovecot/files ] && mkdir -p /data/dovecot/files
[ ! -f /data/dovecot/files/pwd ] && echo " " > /data/dovecot/files/pwd

if [ "$STDOUT_LOGGING" == "true" ]; then
  sed -i '/^\(#\)\?log_path.*/d' /etc/dovecot/dovecot.conf
  sed -i '/^\(#\)\?info_log_path.*/d' /etc/dovecot/dovecot.conf
  sed -i '/^\(#\)\?debug_log_path.*/d' /etc/dovecot/dovecot.conf
  echo 'log_path = /dev/stdout' >> /etc/dovecot/dovecot.conf
  echo 'info_log_path = /dev/stdout' >> /etc/dovecot/dovecot.conf
  echo 'debug_log_path = /dev/stdout' >> /etc/dovecot/dovecot.conf
else
  touch /var/log/dovecot.log
  if [ -f /srv/scripts/logrotate.sh ]; then
	/srv/scripts/logrotate.sh /var/log/dovecot.log
  fi
fi
HOMEDIRS="${HOMEDIRS:-/data/dovecot/home}"
[ ! -d "${HOMEDIRS}" ] && mkdir -p $HOMEDIRS
chown 5000:5000 $HOMEDIRS
chmod 775 $HOMEDIRS

if [ ! -f /etc/dovecot/fullchain.pem ]; then
  cp /etc/ssl/dovecot/server.pem /etc/dovecot/fullchain.pem
  cp /etc/ssl/dovecot/server.key /etc/dovecot/privkey.pem 
fi

if [ -f /servername_cert ]; then
  servername_cert="$(grep "^[[:alnum:]]" /servername_cert|head -n1|tr -d " ")"
  if [ -n "$servername_cert" ]; then
    sed -i "s/^ssl_cert.*$/ssl_cert = <\/data\/certs\/live\/$servername_cert\/fullchain\.pem/" /etc/dovecot/dovecot.conf
    sed -i "s/^ssl_key.*$/ssl_key = <\/data\/certs\/live\/$servername_cert\/privkey.pem/" /etc/dovecot/dovecot.conf
  fi
fi

COMMONDIR="${COMMONDIR:-/data/common}"
[ ! -d "${COMMONDIR}" ] && mkdir -p $COMMONDIR
if [ ! -f "${COMMONDIR}/dh-dovecot.pem" ]; then
  openssl dhparam 2048 > "${COMMONDIR}/dh-dovecot.pem"
fi

if [ "$STDOUT_LOGGING" != "true" ]; then
  exec tail -F /var/log/dovecot.log &
fi
