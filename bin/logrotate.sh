#!/bin/bash

log(){
	echo -n "$(date +%a" "%d-%m-%Y" "%H:%M:%S) --- "
	echo "$1"
}

if [ -z "$1" ]; then
	log "no logs to rotate"
	exit 1
fi

log_rotate(){
	LOG_R="$1"
	if [ -d "$1" ]; then
		for logfile in $(ls "$1"); do
			log_rotate "$1/$logfile"
		done
	else
		EXT=${LOG_R:(-4)}
		if [ "$EXT" = ".log" ] || [[ "$LOG_R" =~ (.*mainlog$|.*rejectlog$|.*paniclog$) ]] ; then
			size="$(stat -c %s "$LOG_R")"
			if [ -s "$LOG_R" ] && [ $size -gt 128000 ]; then
				for num in $(seq 10 -1 1); do
					if [ -f "$LOG_R".$num.gz ]; then
						mv "$LOG_R".$num.gz "$LOG_R".$[$num+1].gz
					fi
				done
				if [ -f "$LOG_R" ]; then
					log "Rotating $LOG_R"
					cp "$LOG_R" "$LOG_R".1
					cat /dev/null > "$LOG_R"
					gzip -9 "$LOG_R".1
				fi
			else
				if [ -f "$LOG_R" ]; then
					log "$LOG_R has size < 128k, not rotating"
				else
					log "$LOG_R does not exists"
				fi
			fi
		else
			log "$LOG_R file will not be rotated (for security reason only files with '.log' extensions or 'mainlog|rejectlog|paniclog' names will be parsed"
		fi
	fi
}

log_rotate "$1"

