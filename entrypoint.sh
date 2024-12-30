#!/bin/sh
set -e

_preflight() {
  echo 'Codecov preflight started.'
  COUNTER=0
  echo 'Waiting for Codecov Default to start ...'

  while [ -z "`nc -vz $CODECOV_DEFAULT_HOST $CODECOV_DEFAULT_PORT 2>&1 | grep open`" ]; do
    COUNTER=$(($COUNTER+1))
    if [ "$COUNTER" -gt 30 ]; then
      echo "Timeout waiting for Codecov Default to start"
      echo "Review documentation: https://docs.codecov.io/docs/configuration"
      exit 1
    elif [ "$COUNTER" -eq 15 ]; then
        echo 'Still waiting for Codecov Default to start ...'
    fi
    sleep 1
  done
  echo 'Codecov Default started.'
  if [ "$CODECOV_GATEWAY_PROXY_MODE_ENABLED" ]; then
      return 0
  fi
  COUNTER=0

  echo 'Waiting for Codecov api to start ...'
  while [ -z "`nc -vz $CODECOV_API_HOST $CODECOV_API_PORT 2>&1 | grep open`" ]; do

    COUNTER=$(($COUNTER+1))
    if [ "$COUNTER" -gt 60 ]; then
      echo "Timeout waiting for Codecov api to start"
      echo "If this is the first boot ever, initial migrations may have taken longer than this timer. Please restart this service (gateway)"
      echo "Check logs on api and ensure proper configuration: https://docs.codecov.io/changelog/release-notes-for-v500#infrastructure for more information"
      exit 1
    elif [ "$COUNTER" -eq 30 ]; then
      echo 'Still waiting for Codecov api to start ...'
    fi
    sleep 1
  done
  echo 'Codecov api started.'
  COUNTER=0
  echo 'Waiting for Codecov ia to start ...'
    while [ -z "`nc -vz $CODECOV_IA_HOST $CODECOV_IA_PORT 2>&1 | grep open`" ]; do

      COUNTER=$(($COUNTER+1))
      if [ "$COUNTER" -gt 30 ]; then
        echo "Timeout waiting for Codecov IA to start"
        echo "Check logs on IA and ensure proper configuration: https://docs.codecov.io/changelog/release-notes-for-v500#infrastructure for more information"
        exit 1
      elif [ "$COUNTER" -eq 15 ]; then
        echo 'Still waiting for Codecov IA to start ...'
      fi
      sleep 1
    done
  echo 'Codecov IA started.'

  echo 'Codecov preflight complete.'
}
_start_haproxy() {
  export DOLLAR='$'
  BACKENDS="-f /etc/haproxy/1-backends.conf"
  routing_map="codecov"
  if [ "$CODECOV_GATEWAY_PROXY_MODE_ENABLED" ]; then
      BACKENDS=""
      routing_map="proxy"
  fi
  export CODECOV_GATEWAY_ROUTING_MAP=${routing_map}
  if [ "$CODECOV_GATEWAY_SSL_ENABLED" ]; then
    echo 'Codecov gateway ssl enabled'
    envsubst < /etc/haproxy/3-ssl.conf.template > /etc/haproxy/2-frontends.conf
  else
    echo 'Codecov gateway ssl disabled'
    envsubst < /etc/haproxy/2-http.conf.template > /etc/haproxy/2-frontends.conf
  fi
  ssl_string="ssl verify none "
  if [ $CODECOV_DEFAULT_SCHEME = "https" ]; then
    export CODECOV_DEFAULT_SSL_FLAG=$ssl_string
  fi
  if [ $CODECOV_API_SCHEME = "https" ]; then
    export CODECOV_API_SSL_FLAG=$ssl_string
  fi
  if [ $CODECOV_IA_SCHEME = "https" ]; then
    export CODECOV_IA_SSL_FLAG=$ssl_string
  fi

  if [ "$CODECOV_GATEWAY_CHROOT_DISABLED" ]; then
    echo 'Codecov gateway chroot disabled'
    envsubst < /etc/haproxy/0-haproxy-no-chroot.conf.template > /etc/haproxy/0-haproxy.conf
  else
    envsubst < /etc/haproxy/0-haproxy.conf.template > /etc/haproxy/0-haproxy.conf
  fi
  BACKENDS="-f /etc/haproxy/1-backends.conf"
  envsubst < /etc/haproxy/1-backends.conf.template > /etc/haproxy/1-backends.conf
  MINIO_FILE=""
  if [ "$CODECOV_GATEWAY_MINIO_ENABLED" ] && [ "$routing_map" != "proxy" ]; then
      echo 'Codecov gateway minio enabled'
      if [ $CODECOV_MINIO_SCHEME = "https" ]; then
          export CODECOV_MINIO_SSL_FLAG=$ssl_string
      fi
      envsubst < /etc/haproxy/1-minio.conf.template > /etc/haproxy/1-minio.conf
      cat /etc/haproxy/minio.map >> /etc/haproxy/codecov.map
      MINIO_FILE="-f /etc/haproxy/1-minio.conf"
  fi
  echo "Starting haproxy"
  haproxy -W -db -f /etc/haproxy/0-haproxy.conf $BACKENDS $MINIO_FILE -f /etc/haproxy/2-frontends.conf
}

if [ -z "$1" ];
then
  _preflight
  _start_haproxy
else
  exec "$@"
fi

