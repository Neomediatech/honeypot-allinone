#!/bin/bash
cd /

LOGDIR="/var/log/clamav"
LOGS="$LOGDIR/clamd.log $LOGDIR/freshclam.log"
CLAMDIR="/var/lib/clamav"
mkdir -p $LOGDIR /run/clamav ; chown clamav:clamav $LOGDIR /run/clamav ; touch $LOGS ; chown clamav:clamav $LOGS ; chmod 777 $LOGDIR ; chmod 666 $LOGS

if [ -d $CLAMDIR ]; then
  chown clamav:clamav $CLAMDIR
fi

if [ -d /usr/local/share/clamav ]; then
  chown clamav:clamav /usr/local/share/clamav
fi

if [ -f /srv/scripts/logrotate.sh ]; then
	/srv/scripts/logrotate.sh /var/log/clamav/
	/srv/scripts/logrotate.sh /var/log/clamav-unofficial-sigs/
fi

for file in bytecode.cvd daily.cvd main.cvd; do
  if [ ! -f $CLAMDIR/$file ]; then
    echo "$CLAMDIR/$file not found, downloading from database.clamav.net..."
    curl -o $CLAMDIR/$file http://database.clamav.net/$file
    chown clamav:clamav $CLAMDIR/$file
  fi
done

# set Clamav Unofficial Sigs
UNOFFICIAL_SIGS=${UNOFFICIAL_SIGS:-yes}
if [ $UNOFFICIAL_SIGS = "yes" ]; then
  BASE_URL="https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master"
  cd /
  curl --fail --show-error --location --output clamav-unofficial-sigs.sh -- ${BASE_URL}/clamav-unofficial-sigs.sh
  chmod +x clamav-unofficial-sigs.sh
  [ ! -d /etc/clamav-unofficial-sigs ] && mkdir -p /etc/clamav-unofficial-sigs
  cd /etc/clamav-unofficial-sigs
  # [ ! -f master.conf ] && 
  curl --fail --show-error --location --output master.conf -- ${BASE_URL}/config/master.conf
  # [ ! -f user.conf ]   && 
  curl --fail --show-error --location --output user.conf   -- ${BASE_URL}/config/user.conf
  if [ ! -f os.conf ]; then
    cat <<EOF > os.conf
clam_user="clamav"
clam_group="clamav"
clam_dbs="/var/lib/clamav"
clamd_socket="/run/clamav/clamd.ctl"
enable_random="no"
# https://eXtremeSHOK.com ######################################################
EOF
  fi
  MISSING=""
  which host 1>/dev/null
  [ $? -ne 0 ] && MISSING="bind9-host"
  which rsync 1>/dev/null
  [ $? -ne 0 ] && MISSING="$MISSING rsync"
  apt-get update 
  apt-get install -y --no-install-recommends $MISSING
  rm -rf /var/lib/apt/lists*
  # prev_file=$(cat /etc/clamav-unofficial-sigs/os.conf)
  # echo 'enable_random="no"' >> /etc/clamav-unofficial-sigs/os.conf
  /clamav-unofficial-sigs.sh --verbose
  # echo "$prev_file" > /etc/clamav-unofficial-sigs/os.conf
  while true; do sleep 3600 ; /clamav-unofficial-sigs.sh --verbose ; done &
fi

