#!/bin/bash

MAILSERVER_CERT=${MAILSERVER_CERT:-noservername.domain.tld}
CERT_DIR="/data/certs/live/${MAILSERVER_CERT}"
LOGDIR=${EXIM_LOGDIR:-/data/log}
HONEYPOT=${HONEYPOT:-false}

cat > /etc/exim4/update-exim4.conf.conf <<EOM
# /etc/exim4/update-exim4.conf.conf
#
# Edit this file and /etc/mailname by hand and execute update-exim4.conf
# yourself or use 'dpkg-reconfigure exim4-config'
#
# Please note that this is _not_ a dpkg-conffile and that automatic changes
# to this file might happen. The code handling this will honor your local
# changes, so this is usually fine, but will break local schemes that mess
# around with multiple versions of the file.
#
# update-exim4.conf uses this file to determine variable values to generate
# exim configuration macros for the configuration file.
#
# Most settings found in here do have corresponding questions in the
# Debconf configuration, but not all of them.
#
# This is a Debian specific file

dc_eximconfig_configtype='internet'
dc_other_hostnames=''
dc_local_interfaces=''
dc_readhost=''
dc_relay_domains=''
dc_minimaldns='false'
dc_relay_nets=''
dc_smarthost=''
CFILEMODE='644'
dc_use_split_config='true'
dc_hide_mailname='true'
dc_mailname_in_oh='true'
dc_localdelivery='maildir_home'
EOM

if [ "$HONEYPOT" == "false" ]; then
  if [ "$LOGDIR" == "stdout" ]; then
    mkdir -p /var/log/exim4
    rm -f /var/log/exim4/{main,reject,panic}log
    ln -s /dev/stdout /var/log/exim4/mainlog
    ln -s /dev/stderr /var/log/exim4/rejectlog
    ln -s /dev/stderr /var/log/exim4/paniclog
    echo 'log_file_path = syslog' > /etc/exim4/conf.d/main/99_custom_log_file_path
  else
    if [ ! -d "${LOGDIR}" ]; then
      mkdir -p "${LOGDIR}"
      #chown Debian-exim:adm "${LOGDIR}"
      #chmod 750 "${LOGDIR}"
      #chmod g+s "${LOGDIR}"
    fi

    if [ ! -f "${LOGDIR}/mainlog" ]; then
      touch "${LOGDIR}/{main,reject,panic}log"
      chown Debian-exim:adm "${LOGDIR}/mainlog"
      chmod 640 "${LOGDIR}/mainlog"
    fi
    echo "log_file_path = $LOGDIR/%slog" > /etc/exim4/conf.d/main/99_custom_log_file_path
  fi
fi

# Check custom configuration files
SRC_DIR="/data/exim4/conf"
DST_DIR="/etc/exim4"
if [ -d "${SRC_DIR}" ]; then
  cd "${SRC_DIR}"
  for FILE in $(find . -type f|cut -b 3-); do
    DIR_FILE="$(dirname "$FILE")"
    if [ ! -d "$DST_DIR/$DIR_FILE" ]; then
      mkdir -p "$DST_DIR/$DIR_FILE"
    fi
    if [ -f "$DST_DIR/$FILE}" ]; then
      echo "  WARNING: $DST_DIR/$FILE already exists and will be overriden"
      rm -f "$DST_DIR/$FILE"
    fi
    echo "  Add custom config file $DST_DIR/$FILE ..."
    ln -sf "$SRC_DIR/$FILE" "$DST_DIR/$FILE"
  done
fi

# exim does not accept exim4.filter as symbolic link, hence we copy it
[ -f ${SRC_DIR}/exim4.filter ] && rm -f /etc/exim4/exim4.filter && cp ${SRC_DIR}/exim4.filter /etc/exim4

if [ -f /run/secrets/dovecot-fqdn-cert.txt ]; then
    MAILSERVER_CERT="$(cat /run/secrets/dovecot-fqdn-cert.txt)"
fi

if [ -d ${CERT_DIR} ]; then
    sed -i "s/^SERVER_CERT.*$/SERVER_CERT=$MAILSERVER_CERT/" /etc/exim4/conf.d/main/00_custom_listmacrodefs
    [ -d /data/certs/archive/$MAILSERVER_CERT ] && chmod 644 /data/certs/archive/$MAILSERVER_CERT/privkey*.pem
else
    mkdir -p ${CERT_DIR}
fi
[ ! -f ${CERT_DIR}/privkey.pem ] && /gencert.sh 

if [ ! -d /proc/sys/net/ipv6 ]; then 
    grep -q disable_ipv6 /etc/exim4/* -R
    if [ $? -ne 0 ]; then
        echo 'disable_ipv6 = true' > /etc/exim4/conf.d/main/99_custom_disable_ipv6
    fi
fi

update-exim4.conf

cmd="/dockerize"
if [ -x "$cmd" ]; then
  checks=""
  if [ -n "$WAITFOR" ]; then
    for CHECK in $WAITFOR; do
      checks="$checks -wait $CHECK"
    done
    $cmd $checks -timeout 180s -wait-retry-interval 15s
    [ $? -ne 0 ] && exit 1
  fi
fi

if [ "$LOGDIR" != "stdout" ]; then
  exec tail -F ${LOGDIR}/mainlog &
fi
