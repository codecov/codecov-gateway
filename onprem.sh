#!/bin/sh
set -e
_start_haproxy() {
  export DOLLAR='$'
  if [ "$CODECOV_GATEWAY_SSL_ENABLED" ]; then
    echo 'Codecov gateway ssl enabled'
    envsubst < /etc/haproxy/onprem-ssl.conf.template > /etc/haproxy/2-frontends.conf
  else
    echo 'Codecov gateway ssl disabled'
    envsubst < /etc/haproxy/onprem-http.conf.template > /etc/haproxy/2-frontends.conf
  fi
 # ssl_string="ssl verify none "
  #if [ $CODECOV_ONPREM_SCHEME = "https" ]; then
  #  export CODECOV_FRONTEND_SSL_FLAG=$ssl_string
  #fi
   if [ "$CODECOV_GATEWAY_CHROOT_DISABLED" ]; then
      echo 'Codecov gateway chroot disabled'
      envsubst < /etc/haproxy/0-haproxy-no-chroot.conf.template > /etc/haproxy/0-haproxy.conf
    else
      envsubst < /etc/haproxy/0-haproxy.conf.template > /etc/haproxy/0-haproxy.conf
    fi
  envsubst < /etc/haproxy/onprem.conf.template > /etc/haproxy/onprem-backends.conf
  echo "Starting haproxy"
  haproxy -W -db -f /etc/haproxy/0-haproxy.conf -f /etc/haproxy/onprem-backends.conf -f /etc/haproxy/2-frontends.conf
}


if [ -z "$1" ];
then
  _start_haproxy
else
  exec "$@"
fi

