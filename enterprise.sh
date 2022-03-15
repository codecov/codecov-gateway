#!/bin/sh
set -e

_preflight() {
  echo 'Codecov preflight started.'
  COUNTER=0
  echo 'Waiting for Codecov to start ...'

  while [ -z "`nc -vz $CODECOV_WEB_HOST $CODECOV_WEB_PORT 2>&1 | grep open`" ]; do
    COUNTER=$(($COUNTER+1))
    if [ "$COUNTER" -gt 30 ]; then
      echo "Timeout waiting for Codecov to start"
      echo "Check database connectivity"
      echo "Check redis connectivity"
      echo "Review documentation: https://docs.codecov.io/docs/configuration"
      exit 1
    elif [ "$COUNTER" -eq 15 ]; then
        echo 'Still waiting for Codecov to start ...'
    fi
    sleep 1
  done
  echo 'Codecov started.'
  COUNTER=0

  echo 'Waiting for Codecov api to start ...'
  while [ -z "`nc -vz $CODECOV_API_HOST $CODECOV_API_PORT 2>&1 | grep open`" ]; do

    COUNTER=$(($COUNTER+1))
    if [ "$COUNTER" -gt 30 ]; then
      echo "Timeout waiting for Codecov api to start"
      echo "Check logs on api and ensure proper configuration: https://docs.codecov.io/changelog/release-notes-for-v460#infrastructure for more information"
      exit 1
    elif [ "$COUNTER" -eq 15 ]; then
      echo 'Still waiting for Codecov api to start ...'
    fi
    sleep 1
  done
  echo 'Codecov api started.'
  COUNTER=0
  echo 'Waiting for Codecov rti to start ...'
    while [ -z "`nc -vz $CODECOV_RTI_HOST $CODECOV_RTI_PORT 2>&1 | grep open`" ]; do

      COUNTER=$(($COUNTER+1))
      if [ "$COUNTER" -gt 30 ]; then
        echo "Timeout waiting for Codecov rti to start"
        echo "Check logs on rti and ensure proper configuration: https://docs.codecov.io/changelog/release-notes-for-v460#infrastructure for more information"
        exit 1
      elif [ "$COUNTER" -eq 15 ]; then
        echo 'Still waiting for Codecov rti to start ...'
      fi
      sleep 1
    done
  echo 'Codecov rti started.'

  echo 'Codecov preflight complete.'
}

_start_nginx() {
  export DOLLAR='$'
  if [ "$CODECOV_GATEWAY_SSL_ENABLED" ]; then
    echo 'Codecov gateway ssl enabled'
    envsubst < /etc/nginx/codecov-ssl.conf.template > /etc/nginx/conf.d/codecov.conf
  else
    echo 'Codecov gateway ssl disabled'
    envsubst < /etc/nginx/codecov.conf.template > /etc/nginx/conf.d/codecov.conf
  fi
  envsubst < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
  envsubst < /etc/nginx/routing.conf.template > /etc/nginx/conf.d/routing.conf
  nginx -g 'daemon off;'
}

if [ -z "$1" ];
then
  _preflight
  _start_nginx
else
  exec "$@"
fi


