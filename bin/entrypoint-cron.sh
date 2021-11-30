#!/bin/bash

SRC_CRON="/data/crontabs/custom.cron"

TMPDIR="/var/cache/cron"
mkdir -p "$TMPDIR"

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

