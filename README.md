# codecov-gateway
Gateway for self hosted. The brains!

[![Build and Push to GCP Artifact Registry](https://github.com/codecov/codecov-gateway/actions/workflows/gcr.yml/badge.svg)](https://github.com/codecov/codecov-gateway/actions/workflows/gcr.yml)
[![Publish Docker image](https://github.com/codecov/codecov-gateway/actions/workflows/release.yml/badge.svg)](https://github.com/codecov/codecov-gateway/actions/workflows/release.yml)

### Purpose
Control routing to various Codecov services. This is meant to be functionally equivalent to ambassador/emissary which we use in production. The primary purpose is to allow independent scaling of various services based on traffic levels.

### Configuration
End user configuration via environment variables was a goal while creating this. As such there are a number of vars that can be set to impact performance.
```text
Format is: VAR=default # info

CODECOV_API_HOST=api  # This is the host to access the codecov api
CODECOV_API_PORT=8000 # The port to access the codecov api
CODECOV_API_SCHEME=http # The scheme on which to access the codecov api. http or https
CODECOV_API_HOST_HEADER="\$http_host" # The host to send as the host header. Default passes through host. Useful to set for local envs.
CODECOV_IA_HOST=IA
CODECOV_IA_PORT=8000
CODECOV_IA_SCHEME=http
CODECOV_IA_HOST_HEADER="\$http_host"
CODECOV_DEFAULT_HOST=frontend
CODECOV_DEFAULT_PORT=5000
CODECOV_DEFAULT_SCHEME=http
CODECOV_DEFAULT_HOST_HEADER="\$http_host"
CODECOV_MINIO_HOST=minio
CODECOV_MINIO_PORT=9000
CODECOV_MINIO_SCHEME=http
CODECOV_MINIO_HOST_HEADER="%[req.hdr(Host)]"
CODECOV_GATEWAY_HTTP_PORT=8080 # Port the gateway listens for traffic on
CODECOV_GATEWAY_HTTPS_PORT=8443 # Port the gateway listens for ssl traffic on if enabled
CODECOV_GATEWAY_CHROOT_DISABLED=null # Default is null. When var is present, chroot will be disabled for haproxy. Workaround for Reddit.
```
### Example configuration
```text
Use public codecov api, local IA and qa for web

CODECOV_API_HOST=api.codecov.io
CODECOV_API_PORT=443
CODECOV_API_SCHEME=https 
CODECOV_API_HOST_HEADER=api.codecov.io
CODECOV_IA_HOST=IA
CODECOV_IA_PORT=8000
CODECOV_IA_SCHEME=http
CODECOV_IA_HOST_HEADER="\$http_host"
CODECOV_DEFAULT_HOST=qa.codecov.dev
CODECOV_DEFAULT_PORT=443
CODECOV_DEFAULT_SCHEME=https
CODECOV_DEFAULT_HOST_HEADER="qa.codecov.dev"
```

### SSL
1. Mount a valid cert in the container at `/etc/codecov/ssl/certs/cert.crt`
2. Configure the env `CODECOV_GATEWAY_SSL_ENABLED=true` 

### Proxy
1. Configure the env `CODECOV_GATEWAY_PROXY_MODE_ENABLED=true`
All requests will now be sent on to the configured CODECOV_DEFAULT host/port.

### Minio
This is mostly intended for when using with docker compose. It makes /export and /archive route to the minio host. To enable minio features use the env var `CODECOV_GATEWAY_MINIO_ENABLED=true`
