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
CODECOV_RTI_HOST=rti
CODECOV_RTI_PORT=8000
CODECOV_RTI_SCHEME=http
CODECOV_RTI_HOST_HEADER="\$http_host"
CODECOV_WEB_HOST=web
CODECOV_WEB_PORT=5000
CODECOV_WEB_SCHEME=http
CODECOV_WEB_HOST_HEADER="\$http_host"
CODECOV_GATEWAY_HTTP_PORT=8080 # Port the gateway listens for traffic on
CODECOV_GATEWAY_HTTPS_PORT=8443 # Port the gateway listens for ssl traffic on if enabled
CODECOV_GATEWAY_NGINX_WORKER_PROCESSES=2 # The number of NGINX worker processes. In most cases, running one worker process per CPU core works well. There are times when you may want to increase this number, such as when the worker processes have to do a lot of disk I/O.
CODECOV_GATEWAY_NGINX_WORKER_CONNECTIONS=1024 # The maximum number of connections that each worker process can handle simultaneously. Most systems have enough resources to support a larger number. The appropriate setting depends on the size of the server and the nature of the traffic, and can be discovered through testing. This can't be higher than `ulimit -n`.
```
### Example configuration
```text
Use public codecov api, local rti and qa for web

CODECOV_API_HOST=api.codecov.io
CODECOV_API_PORT=443
CODECOV_API_SCHEME=https 
CODECOV_API_HOST_HEADER=api.codecov.io
CODECOV_RTI_HOST=rti
CODECOV_RTI_PORT=8000
CODECOV_RTI_SCHEME=http
CODECOV_RTI_HOST_HEADER="\$http_host"
CODECOV_WEB_HOST=qa.codecov.dev
CODECOV_WEB_PORT=443
CODECOV_WEB_SCHEME=https
CODECOV_WEB_HOST_HEADER="qa.codecov.dev"
```

### SSL
This is currently untested. It is not needed for the initial customer (Lyft). For a wider release, we will want to test this. It should be in a working state currently.