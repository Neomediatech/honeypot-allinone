#!/bin/bash

LOGFILE="/var/log/opencanary.log"
touch "${LOGFILE}"
if [ -f /srv/scripts/logrotate.sh ]; then
	/srv/scripts/logrotate.sh "${LOGFILE}"
fi

