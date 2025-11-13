# syntax=docker/dockerfile:1.20
FROM haproxytech/haproxy-alpine:3.3
RUN apk update --no-cache && apk upgrade --no-cache openssl && apk add --no-cache gettext
RUN mkdir -p /etc/codecov/ssl/certs && chown haproxy:haproxy /etc/codecov/ssl/certs && chown haproxy:haproxy /etc/haproxy
COPY --chown=haproxy:haproxy --chmod=644 config/0-haproxy.conf /etc/haproxy/0-haproxy.conf.template
COPY --chown=haproxy:haproxy --chmod=644 config/0-haproxy-no-chroot.conf /etc/haproxy/0-haproxy-no-chroot.conf.template
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chown=haproxy:haproxy --chmod=644 config/3-ssl.conf /etc/haproxy/3-ssl.conf.template
COPY --chown=haproxy:haproxy --chmod=644 config/1-backends.conf /etc/haproxy/1-backends.conf.template
COPY --chown=haproxy:haproxy --chmod=644 config/1-minio.conf /etc/haproxy/1-minio.conf.template
COPY --chown=haproxy:haproxy --chmod=644 config/2-http.conf /etc/haproxy/2-http.conf.template
COPY --chown=haproxy:haproxy --chmod=644 config/codecov.map /etc/haproxy/codecov.map.template
COPY --chown=haproxy:haproxy --chmod=644 config/proxy.map /etc/haproxy/proxy.map
COPY --chown=haproxy:haproxy --chmod=644 config/minio.map /etc/haproxy/minio.map
ENV CODECOV_API_HOST=api
ENV CODECOV_API_PORT=8000
ENV CODECOV_API_SCHEME=http
ENV CODECOV_API_HOST_HEADER="%[req.hdr(Host)]"
ENV CODECOV_API_ADMIN_ENABLED=false
ENV CODECOV_API_ADMIN_PATH=admin
ENV CODECOV_API_ADMIN_DEBUG_ENABLED=false
ENV CODECOV_IA_HOST=api
ENV CODECOV_IA_PORT=8000
ENV CODECOV_IA_SCHEME=http
ENV CODECOV_IA_HOST_HEADER="%[req.hdr(Host)]"
ENV CODECOV_DEFAULT_HOST=frontend
ENV CODECOV_DEFAULT_PORT=8080
ENV CODECOV_DEFAULT_SCHEME=http
ENV CODECOV_DEFAULT_HOST_HEADER="%[req.hdr(Host)]"
ENV CODECOV_MINIO_HOST=minio
ENV CODECOV_MINIO_PORT=9000
ENV CODECOV_MINIO_SCHEME=http
ENV CODECOV_MINIO_HOST_HEADER="%[req.hdr(Host)]"
ENV CODECOV_GATEWAY_HTTP_PORT=8080
ENV CODECOV_GATEWAY_HTTPS_PORT=8443
ARG COMMIT_SHA
ARG VERSION
ENV BUILD_ID=$COMMIT_SHA
ENV BUILD_VERSION=$VERSION
EXPOSE 8080
EXPOSE 8443

RUN chown -R haproxy:haproxy /var/lib/haproxy && mkdir -p /run && chown -R haproxy:haproxy /etc/haproxy && chown -R haproxy:haproxy /run

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
