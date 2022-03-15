# syntax=docker/dockerfile:1.3
FROM alpine:3.15

RUN addgroup -S application && adduser -S codecov -G application
RUN apk update --no-cache && apk upgrade --no-cache python3 openssl && apk add --no-cache nginx supervisor gettext
RUN mkdir -p /etc/codecov/ssl/certs && chown codecov:application /etc/codecov/ssl/certs && mkdir -p /etc/nginx/conf.d && chown codecov:application /etc/nginx/conf.d && chown codecov /etc/nginx/nginx.conf
COPY --chmod=755 enterprise.sh /usr/local/bin/enterprise.sh
COPY --chown=codecov:application --chmod=644 config/base.conf /etc/nginx/nginx.conf.template
COPY --chown=codecov:application --chmod=644 config/routing.conf /etc/nginx/routing.conf.template
COPY --chown=codecov:application --chmod=644 config/codecov.conf /etc/nginx/codecov.conf.template
COPY --chown=codecov:application --chmod=644 config/codecov-ssl.conf /etc/nginx/codecov-ssl.conf.template
RUN chown -R codecov /run && chown -R codecov /var/lib/nginx && chown -R codecov /var/log/nginx

USER codecov
ENV CODECOV_API_HOST=api
ENV CODECOV_API_PORT=8000
ENV CODECOV_API_SCHEME=http
ENV CODECOV_API_HOST_HEADER="\$http_host"
ENV CODECOV_RTI_HOST=rti
ENV CODECOV_RTI_PORT=8000
ENV CODECOV_RTI_SCHEME=http
ENV CODECOV_RTI_HOST_HEADER="\$http_host"
ENV CODECOV_WEB_HOST=web
ENV CODECOV_WEB_PORT=5000
ENV CODECOV_WEB_SCHEME=http
ENV CODECOV_WEB_HOST_HEADER="\$http_host"
ENV CODECOV_GATEWAY_NGINX_PROCESSES=2
ENV CODECOV_GATEWAY_HTTP_PORT=8080
ENV CODECOV_GATEWAY_HTTPS_PORT=8443
ARG COMMIT_SHA
ARG VERSION
ENV BUILD_ID $COMMIT_SHA
ENV BUILD_VERSION $VERSION
EXPOSE 8080
EXPOSE 8443
ENTRYPOINT ["/usr/local/bin/enterprise.sh"]

