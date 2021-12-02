# HoneyPot image
All-in-one HoneyPot image based on Ubuntu.

## Why ?
Yes, I know, one service one container, but... Too many effort to maintain all images.
I'm doing this image because I need to collect ip addresses from spammers, scammers, intruders and all others rats who haunt the web.

# WIP! YHBW!
ATTENTION! Work in progress, this image can eat your keyboard, dont't use it until i'll delete this message

## Which services covers this image?
| Service     | Port(s)    | Program    |
| ----------- | ---------- | ---------- |
| POP3/IMAP   | 110/143    | Dovecot    |
| POP3S/IMAPS | 995/993    | Dovecot    |
| SMTP/SMTPS  | 25/465/587 | Exim4      |
| FTP         | 21         | OpenCanary |
| HTTP proxy  | 8080       | OpenCanary |
| MySQL       | 3306       | OpenCanary |
| SSH         | 22         | OpenCanary |
| Redis       | 6379       | OpenCanary |
| RDP         | 3389       | OpenCanary |
| SNMP        | 161        | OpenCanary |
| NTP         | 123        | OpenCanary |
| TFTP        | 69         | OpenCanary |
| Telnet      | 23         | OpenCanary |
| MSSQL       | 1433       | OpenCanary |
| VNC         | 5900       | OpenCanary |
| HTTP/HTTPS  | 80/443     | Nginx/PHP-FPM |

## Custom Exim4 ACL
You can ovveride the file conf.d/acl/acl_pre_smtp_connect with your own acl defiintions. Will be included at the begin of `acl_smtp_connect`

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
# *  *  *  *  * command to be executed
  *  *  *  *  * /usr/bin/date >> /tmp/date.log
  30 20 *  *  * /other/command
```

