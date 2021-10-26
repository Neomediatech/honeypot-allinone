FROM neomediatech/ubuntu-base:20.04
ENV VERSION=2021.1001 \
    DCC_VERSION=2.3.168 \
    SERVICE=honeypot

LABEL maintainer="docker-dario@neomediatech.it" \ 
      org.label-schema.version=$VERSION \
      org.label-schema.vcs-type=Git \
      org.label-schema.vcs-url=https://github.com/Neomediatech/${SERVICE} \
      org.label-schema.maintainer=Neomediatech

RUN apt-get update && apt-get -y dist-upgrade && \
    apt-get install -y --no-install-recommends --no-install-suggests \
    bind9 \
    python3 python3-pip \
    razor \
    apt-utils ca-certificates ssl-cert curl gcc libc-dev make \
    redis \
    clamav clamav-daemon clamav-freshclam clamav-unofficial-sigs \
    lsb-release wget gnupg \
    mariadb-client exim4-daemon-heavy libswitch-perl openssl && \
    pip install setuptools && \
    pip install wheel && \
    pip install pyzor && \
    sed -i 's/\.iteritems/\.items/' /usr/local/lib/python3.8/dist-packages/pyzor/client.py && \
    sed -i 's/ xrange(/ range(/' /usr/local/lib/python3.8/dist-packages/pyzor/digest.py && \
    addgroup razor && \
    adduser --gecos "razor antispam" --ingroup razor --disabled-password razor && \
    curl https://www.dcc-servers.net/dcc/source/old/dcc-${DCC_VERSION}.tar.Z | tar xzf - -C /tmp && ls -l /tmp && \
    cd /tmp/dcc-${DCC_VERSION} && ./configure --disable-dccm && make install && \
    addgroup user && \
    adduser --gecos "dcc user" --ingroup user --disabled-password user && \
    mkdir -p /run/named && chown bind /run/named && \
    mkdir -p /var/run/clamav && \
    chown clamav:clamav /var/run/clamav && \
    CODENAME=`lsb_release -c -s` && \
    wget -O- https://rspamd.com/apt-stable/gpg.key | apt-key add - && \
    echo "deb [arch=amd64] http://rspamd.com/apt-stable/ $CODENAME main" > /etc/apt/sources.list.d/rspamd.list && \
    echo "deb-src [arch=amd64] http://rspamd.com/apt-stable/ $CODENAME main" >> /etc/apt/sources.list.d/rspamd.list && \
    apt-get update && \
    apt-get --no-install-recommends install -y rspamd && \
    curl https://repo.dovecot.org/DOVECOT-REPO-GPG | gpg --import && \
    gpg --export ED409DA1 > /etc/apt/trusted.gpg.d/dovecot.gpg && \
    echo "deb https://repo.dovecot.org/ce-2.3-latest/ubuntu/focal focal main" > /etc/apt/sources.list.d/dovecot.list && \
    apt update && \
    apt install -y --no-install-recommends dovecot-core dovecot-imapd dovecot-lmtpd \
            dovecot-mysql dovecot-pop3d dovecot-sieve dovecot-sqlite dovecot-submissiond && \
    groupadd -g 5000 vmail && useradd -u 5000 -g 5000 vmail -d /srv/mail && passwd -l vmail && \
    rm -rf /etc/dovecot && mkdir -p /srv/mail && chown vmail:vmail /srv/mail && \
    make-ssl-cert generate-default-snakeoil && \
    mkdir /etc/dovecot && ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/dovecot/fullchain.pem && \
    ln -s /etc/ssl/private/ssl-cert-snakeoil.key /etc/dovecot/privkey.pem && \
    apt-get purge -yq binutils cpp gcc libc6-dev linux-libc-dev make && \
    apt-get -y autoremove --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/log/* /var/tmp/* /usr/share/man/??_* /usr/share/man/?? /usr/local/share/doc /usr/local/share/man

COPY --chown=razor:razor conf/razor-agent.conf /home/razor/.razor

COPY conf/dcc_conf /var/dcc/dcc_conf

COPY --chown=_rspamd:_rspamd conf/rspamd/local.d/* /etc/rspamd/local.d/

WORKDIR /srv/scripts
COPY bin/* ./
RUN chmod +x entrypoint.sh entrypoint-rspamd.sh entrypoint-exim.sh entrypoint-clamav.sh entrypoint-dovecot.sh init.sh gencert.sh razorfy.pl && \
    cp digest.py /usr/local/lib/python3.8/dist-packages/pyzor/digest.py 

WORKDIR /
EXPOSE 53 5953 5954 11342 10030 3310 25 465 587


# HEALTHCHECK --interval=30s --timeout=30s --start-period=20s --retries=20 CMD nc -w 7 -zv 0.0.0.0 5953
# need some best idea

ENTRYPOINT ["/srv/scripts/entrypoint.sh"]


CMD ["tail", "-F", "/var/log/exim4/mainlog"]

