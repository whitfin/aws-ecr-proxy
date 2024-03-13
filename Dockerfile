FROM openresty/openresty:1.21.4.3-alpine
USER root

RUN apk add -v --no-cache \
        bind-tools \
        gettext \
        python3 \
        py-pip \
        supervisor && \
    mkdir /cache && \
    addgroup -g 110 nginx && \
    adduser -u 110 -D -S -h /cache -s /sbin/nologin -G nginx nginx && \
    pip install --break-system-packages --upgrade pip awscli==1.30.1 && \
    apk -v --purge del py-pip

COPY bin/*.sh /startup.sh
COPY templates /templates

HEALTHCHECK \
    --interval=5s \
    --timeout=5s \
    --retries=3 \
    CMD sh /health-check.sh

ENTRYPOINT ["/startup.sh"]

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
