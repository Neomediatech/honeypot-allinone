#!/bin/bash

MAILSERVER_CERT=${MAILSERVER_CERT:-noservername.domain.tld}
CERT_DIR="/data/certs/live/${MAILSERVER_CERT}"
LOGDIR=${EXIM_LOGDIR:-/var/log/exim4}
HONEYPOT=${HONEYPOT:-false}

if [ "$HONEYPOT" == "false" ]; then
  if [ "$LOGDIR" == "stdout" ]; then
    mkdir -p /var/log/exim4
    rm -f /var/log/exim4/{mainlog,rejectlog,paniclog}
    ln -s /dev/stdout /var/log/exim4/mainlog
    ln -s /dev/stderr /var/log/exim4/rejectlog
    ln -s /dev/stderr /var/log/exim4/paniclog
    echo 'log_file_path = syslog' > /etc/exim4/conf.d/main/02_custom
  else
    if [ ! -d "${LOGDIR}" ]; then
      mkdir -p "${LOGDIR}"
      chown Debian-exim:adm "${LOGDIR}"
      chmod 750 "${LOGDIR}"
      chmod g+s "${LOGDIR}"
    fi

    if [ ! -f "${LOGDIR}/mainlog" ]; then
      touch "${LOGDIR}/mainlog"
      chown Debian-exim:adm "${LOGDIR}/mainlog"
      chmod 640 "${LOGDIR}/mainlog"
    fi
  fi
fi

# Check custom configuration files
SRC_DIR="/data/conf"
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
    sed -i "s/^SERVER_CERT.*$/SERVER_CERT=$MAILSERVER_CERT/" /etc/exim4/conf.d/main/00_exim4-config_listmacrosdefs-custom
    [ -d /data/certs/archive/$MAILSERVER_CERT ] && chmod 644 /data/certs/archive/$MAILSERVER_CERT/privkey*.pem
else
    mkdir -p ${CERT_DIR}
fi
[ ! -f ${CERT_DIR}/privkey.pem ] && /gencert.sh 

if [ ! -d /proc/sys/net/ipv6 ]; then 
    grep -q disable_ipv6 /etc/exim4/* -R
    if [ $? -ne 0 ]; then
        echo 'disable_ipv6 = true' > /etc/exim4/conf.d/main/01_custom
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
