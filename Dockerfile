FROM neomediatech/ubuntu-base:20.04
ENV VERSION=2021.1027 \
    DCC_VERSION=2.3.168 \
    SERVICE=honeypot-allinone

LABEL maintainer="docker-dario@neomediatech.it" \ 
      org.label-schema.version=$VERSION \
      org.label-schema.vcs-type=Git \
      org.label-schema.vcs-url=https://github.com/Neomediatech/${SERVICE} \
      org.label-schema.maintainer=Neomediatech

RUN apt-get update && apt-get install -y --no-install-recommends --no-install-suggests \
    lsb-release wget gnupg curl ca-certificates && \
    CODENAME=`lsb_release -c -s` && \
    wget -O- https://rspamd.com/apt-stable/gpg.key | apt-key add - && \
    echo "deb [arch=amd64] http://rspamd.com/apt-stable/ $CODENAME main" > /etc/apt/sources.list.d/rspamd.list && \
    echo "deb-src [arch=amd64] http://rspamd.com/apt-stable/ $CODENAME main" >> /etc/apt/sources.list.d/rspamd.list && \
    curl https://repo.dovecot.org/DOVECOT-REPO-GPG | gpg --import && \
    gpg --export ED409DA1 > /etc/apt/trusted.gpg.d/dovecot.gpg && \
    echo "deb https://repo.dovecot.org/ce-2.3-latest/ubuntu/focal focal main" > /etc/apt/sources.list.d/dovecot.list && \
    apt-get update && apt-get -y dist-upgrade && \
    apt-get install -y --no-install-recommends --no-install-suggests \
    bind9 \
    python3 python3-pip \
    razor \
    apt-utils ssl-cert gcc libc-dev make \
    redis \
    dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql dovecot-pop3d dovecot-sieve dovecot-sqlite dovecot-submissiond \
    clamav clamav-daemon clamav-freshclam clamav-unofficial-sigs \
    mariadb-client exim4-daemon-heavy libswitch-perl openssl \
    sudo \
    virtualenv g++ gcc \
    rspamd adns-tools ipset && \
    pip install setuptools && \
    pip install wheel && \
    pip install pyzor && \
    PY_VER="$(python3 -V|cut -d " " -f2|cut -d. -f1,2)" && \
    sed -i 's/\.iteritems/\.items/' /usr/local/lib/python${PY_VER}/dist-packages/pyzor/client.py && \
    sed -i 's/ xrange(/ range(/' /usr/local/lib/python${PY_VER}/dist-packages/pyzor/digest.py && \
    addgroup razor && \
    adduser --gecos "razor antispam" --ingroup razor --disabled-password razor && \
    curl https://www.dcc-servers.net/dcc/source/old/dcc-${DCC_VERSION}.tar.Z | tar xzf - -C /tmp && ls -l /tmp && \
    cd /tmp/dcc-${DCC_VERSION} && ./configure --disable-dccm && make install && \
    addgroup user && \
    adduser --gecos "dcc user" --ingroup user --disabled-password user && \
    mkdir -p /run/named && chown bind /run/named && \
    mkdir -p /var/run/clamav && \
    chown clamav:clamav /var/run/clamav && \
    groupadd -g 5000 vmail && useradd -u 5000 -g 5000 vmail -d /data/dovecot/home/vmail && passwd -l vmail && \
    rm -rf /etc/dovecot && mkdir -p /data/dovecot/home/vmail && chown vmail:vmail /data/dovecot/home/vmail && \
    make-ssl-cert generate-default-snakeoil && \
    mkdir /etc/dovecot && ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/dovecot/fullchain.pem && \
    ln -s /etc/ssl/private/ssl-cert-snakeoil.key /etc/dovecot/privkey.pem && \
    mkdir -p /opt/opencanary /var/log/nginx /etc/firehol /srv/common && \
    touch /var/log/nginx/access.log /var/log/nginx/error.log && \
    apt-get install -y --no-install-suggests \
    python3-dev python3-pip python3-virtualenv python3-venv python3-scapy python3-wheel libssl-dev libpcap-dev samba \
    php7.4-fpm nginx-extras cron whois && \
    virtualenv /opt/opencanary/virtualenv && \
    . /opt/opencanary/virtualenv/bin/activate && \
    pip install pip --upgrade && \
    pip install opencanary scapy pcapy && \
    PY_VER="$(python3 -V|cut -d " " -f2|cut -d. -f1,2)" && \
    cp /opt/opencanary/virtualenv/lib/python${PY_VER}/site-packages/opencanary/logger.py \
       /opt/opencanary/virtualenv/lib/python${PY_VER}/site-packages/opencanary/logger.py.orig && \
    ln -s /opt/opencanary/virtualenv/lib/python${PY_VER} /opt/opencanary/virtualenv/lib/python && \
    echo "listen = 127.0.0.1:9000" >> /etc/php/7.4/fpm/pool.d/www.conf && \
    apt-get purge -yq binutils cpp gcc g++ libc6-dev linux-libc-dev make build-essential libpcap-dev libffi-dev libssl-dev python-dev && \
    apt-get -y autoremove --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/log/* /var/tmp/* /usr/share/man/??_* /usr/share/man/?? \
           /usr/local/share/doc /usr/local/share/man /root/.cache \
	   /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.monthly /etc/cron.weekly

COPY bin/opencanary/logger.py /opt/opencanary/virtualenv/lib/python/site-packages/opencanary/logger.py

COPY conf/exim4/conf.d/ /etc/exim4/conf.d/

COPY conf/ /tmp/conf/
WORKDIR /tmp/conf
RUN mv razor-agent.conf /home/razor/.razor && \
    chown razor:razor /home/razor/.razor && \
    mv dcc_conf /var/dcc/dcc_conf && \
    mkdir -p /etc/rspamd/local.d/ && \
    mv rspamd/local.d/* /etc/rspamd/local.d/ && \
    chown -R _rspamd:_rspamd /etc/rspamd/local.d/ && \
    mv dovecot/* /etc/dovecot/ && \
    mv opencanary/opencanary.conf /root/.opencanary.conf && \
    mv nginx/default /etc/nginx/sites-enabled/ && \
    rm -rf /var/www/html && \
    mv nginx/html /var/www/html && \
    mv dnsbl-ipset.conf /etc/firehol/ && \
    mv manual-blacklisted-ip.conf /srv/common/ && \
    cd / && rm -rf /tmp/conf

WORKDIR /srv/scripts
COPY bin/ /srv/scripts/

RUN chmod +x *.sh *.pl && \
    PY_VER="$(python3 -V|cut -d " " -f2|cut -d. -f1,2)" && \
    cp digest.py /usr/local/lib/python${PY_VER}/dist-packages/pyzor/digest.py

WORKDIR /
EXPOSE 53 5953 5954 11342 10030 3310 25 465 587 80 443 110 143 993 995

# HEALTHCHECK --interval=30s --timeout=30s --start-period=20s --retries=20 CMD nc -w 7 -zv 0.0.0.0 5953
# need some best idea

ENTRYPOINT ["/srv/scripts/entrypoint.sh"]

CMD ["tail", "-F", "/var/log/exim4/mainlog"]

