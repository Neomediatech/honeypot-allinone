#!/bin/bash

cat <<EOF > /etc/crontab

SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name command to be executed

EOF

SRC_CRON="/data/crontabs/custom.cron"

TMPDIR="/var/cache/cron"
mkdir -p "$TMPDIR"

touch /var/log/cron.log

if [ -f /srv/scripts/logrotate.sh ]; then
	/srv/scripts/logrotate.sh /var/log/cron.log
fi

# if cron file exists calculate MD5 for it and put in "orig-cron.md5" file, then execute crontab
if [ ! -f "$SRC_CRON" ]; then
  mkdir -p "$SRC_CRON"
  echo "#" >> "$SRC_CRON"
fi
md5sum "$SRC_CRON" > "$TMPDIR"/orig-cron.md5
crontab "$SRC_CRON"

# run this script to check new crontabs
/srv/scripts/check-cron.sh &

tail -F /var/log/cron.log &

