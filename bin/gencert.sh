#!/bin/sh -e
MAILSERVER_CERT=${MAILSERVER_CERT:-noservername.domain.tld}
CERT_DIR="${CERT_DIR:-/data/certs/live/${MAILSERVER_CERT}}"

[ ! -d ${CERT_DIR} ] && mkdir -p ${CERT_DIR}

CERT=${CERT_DIR}/fullchain.pem
KEY=${CERT_DIR}/privkey.pem
# valid for three years
DAYS=1095

#SSLEAY=/tmp/exim.ssleay.$$.cnf
SSLEAY="$(tempfile -m600 -pexi)"

cat > $SSLEAY <<EOM
[ req ]
default_bits = 2048
default_keyfile = exim.key
distinguished_name = req_distinguished_name
prompt = no
[ req_distinguished_name ]
countryName = NN
stateOrProvinceName = NoWhere
localityName = IvryUr
organizationName = MyCorp
organizationalUnitName = MyOU
commonName = ${MAILSERVER_CERT}
emailAddress = notme@${MAILSERVER_CERT}
EOM

echo "[*] Creating a self signed SSL certificate for Exim!"
echo "    This may be sufficient to establish encrypted connections but for"
echo "    secure identification you need to buy a real certificate!"
echo "    "
echo "    Please enter the hostname of your MTA at the Common Name (CN) prompt!"
echo "    "

openssl req -config $SSLEAY -x509 -newkey rsa:2048 -keyout $KEY -out $CERT -days $DAYS -nodes
#see README.Debian.gz*# openssl dhparam -check -text -5 512 -out $DH
rm -f $SSLEAY

chown root:Debian-exim $KEY $CERT $DH
chmod 640 $KEY $CERT $DH

echo "[*] Done generating self signed certificates for exim!"
echo "    Refer to the documentation and example configuration files"
echo "    over at /usr/share/doc/exim4-base/ for an idea on how to enable TLS"
echo "    support in your mail transfer agent."
