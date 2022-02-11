#!/bin/bash

if [ ! -d /data ]; then
  mkdir -p /data
fi

chmod 777 /data 

SEP="----------------------------------"

cd /srv/scripts

# ------------------
#  CRON

NAME="cron"
echo $SEP
echo "running $NAME..."

./entrypoint-cron.sh
$NAME
echo -e "\n"

# ------------------
#  BIND9

NAME="bind9"
echo $SEP
echo "running $NAME..."

named -u bind
echo "nameserver 127.0.0.1" > /etc/resolv.conf
echo -e "\n"

# ------------------
#  PYZOR

NAME="pyzor"
echo $SEP
echo "running $NAME..."

PYZOR_SERVER=${PYZOR_SERVER:-}

if [ "${PYZOR_SERVER}" != "" ]; then
    mkdir -p /root/.pyzor
    echo "${PYZOR_SERVER}:24441" > /root/.pyzor/servers
fi

#exec /tini -e 143 -- python3 ./pyzorsocket.py 0.0.0.0 5953
cd /srv/scripts
python3 ./pyzorsocket.py 0.0.0.0 5953 &
echo -e "\n"

# ------------------
#  RAZOR

NAME="razor"
echo $SEP
echo "running $NAME..."

#display environment variables passed with --env
echo "\$RAZORFY_DEBUG= $RAZORFY_DEBUG"
echo "\$RAZORFY_BINDPORT= $RAZORFY_BINDPORT"
echo "\$RAZORFY_MAXTHREADS= $RAZORFY_MAXTHREADS"
echo

NME=razor
    
echo "export RAZORFY_BINDADDRESS=0.0.0.0" > /home/"$NME"/.profile
[ -n "$RAZORFY_DEBUG" ] && echo "export RAZORFY_DEBUG=$RAZORFY_DEBUG" >> /home/"$NME"/.profile
[ -n "$RAZORFY_BINDPORT" ] &&  echo "export RAZORFY_BINDPORT=$RAZORFY_BINDPORT" >> /home/"$NME"/.profile
[ -n "$RAZORFY_MAXTHREADS" ] &&  echo "export RAZORFY_MAXTHREADS=$RAZORFY_MAXTHREADS" >> /home/"$NME"/.profile

echo "Starting razorfy at $(date +'%x %X')"
echo "Changing to user $NME"
su -c 'cd /srv/scripts ; ./razorfy.pl' - "$NME" &
echo -e "\n"

# ------------------
#  PYZOR-CC

NAME="pyzor-cc"
echo $SEP
echo "running $NAME..."

python3 ./pyzorsocket.py 0.0.0.0 5954 &
echo -e "\n"

# ------------------
#  DCC

NAME="dcc"
echo $SEP
echo "running $NAME..."

rm -rf /var/dcc/log
mkdir -p /var/dcc/log
chown -R user:user /var/dcc

/var/dcc/libexec/rcDCC -m dccifd start &
echo -e "\n"

# ------------------
#  REDIS

NAME="redis"
echo $SEP
echo "running $NAME..."

sysctl net.core.somaxconn=511 || ok=1
redis-server --port 6380 &
echo -e "\n"

# ------------------
#  DOVECOT

NAME="dovecot"

if [ -n "$DOVECOT_START" ] && [ "$DOVECOT_START" = "no" ]; then
  echo "NOT running $NAME because of '\$DOVECOT_START=no' setting"
else
  echo $SEP
  echo "running $NAME..."

  ./entrypoint-dovecot.sh
  dovecot
  echo -e "\n"
fi

# ------------------
#  OPENCANARY

NAME="opencanary"

if [ -n "$OPENCANARY_START" ] && [ "$OPENCANARY_START" = "no" ]; then
  echo "NOT running $NAME because of '\$OPENCANARY_START=no' setting"
else
  echo $SEP
  echo "running $NAME..."
  ./entrypoint-opencanary.sh
  ./startcanary.sh
  echo -e "\n"
fi

# ------------------
#  PHP-FPM

NAME="php-fpm7.4"
echo $SEP
echo "running $NAME..."

./entrypoint-php-fpm.sh
$NAME
echo -e "\n"

# ------------------
#  NGINX

NAME="nginx"
echo $SEP
echo "running $NAME..."

./entrypoint-nginx.sh
$NAME
echo -e "\n"

# ------------------
#  CLAMAV

NAME="clamav"
echo $SEP

if [ -n "$CLAMAV_ENABLED" ] && [ "$CLAMAV_ENABLED" = "yes" ]; then
	echo "running $NAME..."

	mkdir -p /var/log/clamav /run/clamav
	chown -R clamav:clamav /var/log/clamav/ /run/clamav/
	#sed -i 's/DatabaseDirectory .*$/DatabaseDirectory \/data\/clamav\/defs/' /etc/clamav/clamd.conf
	#sed -i 's/DatabaseDirectory .*$/DatabaseDirectory \/data\/clamav\/defs/' /etc/clamav/freshclam.conf
	./entrypoint-clamav.sh
	freshclam
	freshclam --daemon
	clamd
else
	mkdir -p "/data/rspamd/conf/local.d"
	echo "$NAME DISABLED by \$CLAMAV_ENABLED docker ENV variable"
	echo "# $NAME DISABLED by \$CLAMAV_ENABLED=$CLAMAV_ENABLED docker ENV variable" > "/data/rspamd/conf/local.d/antivirus.conf"
fi
echo -e "\n"

# ------------------
#  RSPAMD

NAME="rspamd"
echo $SEP
echo "running $NAME..."

./entrypoint-rspamd.sh
mkdir -p /run/rspamd/ && chown _rspamd:_rspamd /run/rspamd/
rspamd -u _rspamd -g _rspamd
echo -e "\n"

# ------------------
#  dnsbl-ipset.sh

NAME="dnsbl-ipset.sh"
echo $SEP
echo "running $NAME..."

./entrypoint-dnsbl-ipset.sh
./dnsbl-ipset.sh start >& /dev/null
echo -e "\n"

# ------------------
#  CHECK MANUAL BLACKLISTED IP/NETWORK ADDRESSES

BLFILE="/srv/common/manual-blacklisted-ip.conf"
if [ -s "$BLFILE" ]; then
  echo "adding blacklisted IP from $BLFILE..."
  [ ! -d /var/log ] && mkdir -p /var/log
  [ -f /var/log/manual-blacklisted-ip.log ] && cat /dev/null > /var/log/manual-blacklisted-ip.log
  cat "$BLFILE" |grep "^[[:digit:]]" | awk '{print d" "$1}' d="$(date '+%Y-%m-%d %H:%M:%S')" > /var/log/manual-blacklisted-ip.log
fi

#  UPTIMEROBOT.COM IP TO BLACKLIST
wget -q https://uptimerobot.com/inc/files/ips/IPv4.txt -O /tmp/uptimerobot_ip.txt
if [ -s /tmp/uptimerobot_ip.txt ]; then
  cat /tmp/uptimerobot_ip.txt |grep "^[[:digit:]]" | awk '{print d" "$1}' d="$(date '+%Y-%m-%d %H:%M:%S')" >> /var/log/manual-blacklisted-ip.log 
fi
rm -f /tmp/uptimerobot_ip.txt

# ------------------
#  OTHER CUSTOM SERVICES/SCRIPTS

CSPATH="/srv/scripts/custom"
if [ -d $CSPATH ]; then
  for script in $(ls $CSPATH); do
    echo $SEP
    echo "running custom script $CSPATH/$script..."
    bash $CSPATH/$script
    echo -e "\n"
  done
fi

# below the last service to start

# ------------------
#  EXIM

NAME="exim"
echo $SEP
echo "running $NAME..."

./entrypoint-exim.sh
mkdir -p /var/log/exim4 /var/spool/exim4
chown Debian-exim:Debian-exim /var/log/exim4 /var/spool/exim4
/usr/sbin/exim4 -bd -q1m
echo -e "\n"


