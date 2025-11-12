FROM openresty/openresty:1.27.1.2-alpine-slim

# Add required dependnecies
RUN apk add -v --no-cache \
        bind-tools \
        gettext \
        python3 \
        py-pip && \
    \
    # Create nginx directories
    mkdir -p \
        /var/cache/nginx/proxy \
        /var/cache/nginx/proxy_temp \
        /var/lib/nginx \
        /var/log/nginx && \
    \
    # Create the nginx user
    addgroup -g 101 nginx && \
    adduser -u 101 -D -S -h /var/lib/nginx -s /sbin/nologin -G nginx nginx && \
    \
    # Configure ownership and permissions of our nginx directories
    chown -R nginx:nginx /var/cache/nginx /var/lib/nginx /var/log/nginx && \
    chmod -R 755 /var/cache/nginx && \
    \
    # Install the AWS CLI with a pinned version to make sure it works...
    pip install --break-system-packages --upgrade pip awscli==1.30.1 && \
    apk -v --purge del py-pip

# Copy local file requirements
COPY bin/startup.sh /startup.sh
COPY templates /templates

# Add health scripts
HEALTHCHECK \
    --interval=5s \
    --timeout=5s \
    --retries=3 \
    CMD sh /scripts/health-check.sh

# Always run the bootstrapping
ENTRYPOINT ["/startup.sh"]

# Run nginx without daemon on start
CMD ["nginx", "-g", "daemon off;"]
