# HoneyPot image
All-in-one HoneyPot image based on Ubuntu.

## Why ?
Yes, I know, one service one container, but... Too many effort to maintain all images.
I'm doing this image because I need to collect ip addresses from spammers, scammers, intruders and all others rats who haunt the web.

# WIP! YHBW!
ATTENTION! Work in progress, this image can eat your keyboard, dont't use it until i delete this message

## Custom crontabs 
If you wish to run custom crontabs create the file `/data/crontabs/custom.cron` and put every crontab you want, for example:  
```
# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name command to be executed
  *  *  *  *  * root      /usr/bin/date >> /tmp/date.log
  30 20 *  *  * root      /other/command
```

