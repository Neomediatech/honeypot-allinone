#!/bin/bash

SRC_CRON="/data/crontabs/custom.cron"

TMPDIR="/var/cache/cron"
mkdir -p "$TMPDIR"

echo "$(date "+%Y-%m-%d %H:%M:%S") --- Running check for crontab file changes from $SRC_CRON" >> /var/log/cron.log

# loop forever
while true; do
  # check if original cron and actual cron exists
  if [ -f "$SRC_CRON" ] && [ -f "$TMPDIR"/orig-cron.md5 ]; then
    # grab path for the cron file to check if it exists
    FILE="$(cat "$TMPDIR"/orig-cron.md5 | awk '{print $2}' | head -n 1)"
    if [ -f "$FILE" ]; then
      # check if cron is changed; if yes install it
      md5sum -c "$TMPDIR"/orig-cron.md5 1>/dev/null 2>/dev/null
      if [ $? -ne 0 ]; then
	crontab "$SRC_CRON" 2>/dev/null
	if [ $? -eq 0 ]; then
	  echo "$(date "+%Y-%m-%d %H:%M:%S") --- Installed new crontab from $SRC_CRON" >> /var/log/cron.log
	  md5sum "$SRC_CRON" > "$TMPDIR"/orig-cron.md5
	else
	  echo "$(date "+%Y-%m-%d %H:%M:%S") --- Unable to install new crontab from $SRC_CRON" >> /var/log/cron.log
	fi
      fi
    fi
  fi

  sleep 60
done

