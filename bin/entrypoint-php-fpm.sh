#!/bin/bash

if [ -n ${PROJECT_HONEY_POT_API_KEY} ]; then
  sed -i '/env\[PROJECT_HONEY_POT_API_KEY\] = .*/d' /etc/php/7.4/fpm/pool.d/www.conf
  echo "env[PROJECT_HONEY_POT_API_KEY] = ${PROJECT_HONEY_POT_API_KEY}" >> /etc/php/7.4/fpm/pool.d/www.conf
fi

mkdir -p /var/log
touch /var/log/http_err.log /var/log/http_spam_access.log
chmod 666 /var/log/http_err.log /var/log/http_spam_access.log

