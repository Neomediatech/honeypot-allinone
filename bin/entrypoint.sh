#!/bin/bash

if [ ! -d /data ]; then
  mkdir -p /data
fi

mkdir -p /data/log

chmod 777 /data /data/log

SEP="----------------------------------"

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
redis-server &
echo -e "\n"

# ------------------
#  CLAMAV

NAME="clamav"
echo $SEP
echo "running $NAME..."

mkdir -p /var/log/clamav /run/clamav
chown -R clamav:clamav /var/log/clamav/ /run/clamav/
#sed -i 's/DatabaseDirectory .*$/DatabaseDirectory \/data\/clamav\/defs/' /etc/clamav/clamd.conf
#sed -i 's/DatabaseDirectory .*$/DatabaseDirectory \/data\/clamav\/defs/' /etc/clamav/freshclam.conf
./entrypoint-clamav.sh
freshclam
freshclam --daemon
clamd
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
#  EXIM

NAME="exim"
echo $SEP
echo "running $NAME..."

./init.sh
./entrypoint-exim.sh
/usr/sbin/exim4 -bd -q1m


