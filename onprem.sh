#!/bin/sh
set -e
_start_haproxy() {
  export DOLLAR='$'
  envsubst < /etc/haproxy/0-haproxy.conf.template > /etc/haproxy/0-haproxy.conf
    envsubst < /etc/haproxy/onprem.conf.template > /etc/haproxy/onprem.conf
  fi
  echo "Starting haproxy"
  haproxy -W -db -f /etc/haproxy/0-haproxy.conf -f /etc/haproxy/onprem.conf
}

if [ -z "$1" ];
then
  _start_haproxy
else
  exec "$@"
fi

