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

## Custom entrypoints
You can run your own scripts/services just before the last, bind mounting `/srv/scripts/custom` directory.  
Put here one or more bash script and it/they will be executed in entrypoint phase.  

## Project HoneyPot API Key
Put in `/data/common/prj-honeypot-api.key` your Project HoneyPot API Key, taken from https://www.projecthoneypot.org for free.  
Or set the ENV var PROJECT_HONEY_POT_API_KEY (TBD)  

## dnsbl-ipset.sh integration
(Taken from https://github.com/firehol/firehol/tree/master/contrib but customi[s|z]ed for our use)  
On the host create the file `/etc/rsyslog.d/30-your-preferred-name.conf`  
And write this code:
```
:msg,contains,"AUDIT " /srv/data/fail2ban/logs/honeypot/iptables-audit.log
& stop
```

Then create this ipset with this commands:  
```
ipset create private_nets hash:net comment  
ipset add private_nets 10.0.0.0/8  
ipset add private_nets 192.168.0.0/16  
ipset add private_nets 172.16.0.0/12  
```  

Then add in your iptables rules this:  
`iptables -I DOCKER-USER -p tcp -m state --state NEW -m set ! --match-set private_nets src -j LOG --log-level debug --log-prefix "AUDIT "`  

## Censys network block
Censys (https://about.censys.io/) scans too many times our hosts, hence we block their IPs/Networks.  
Their networks are: 192.35.168.0/23, 162.142.125.0/24, 167.248.133.0/24, 167.94.138.0/24, 167.94.145.0/24, and 167.94.146.0/24.  
See [conf/manual-blacklisted-ip.conf](conf/manual-blacklisted-ip.conf).  

