FROM openresty/openresty:1.27.1.2-alpine-apk

# Add required dependnecies
RUN apk add -v --no-cache \
        bind-tools \
        gettext \
        python3 \
        py-pip \
    # Create nginx directories
    && mkdir -p \
        /var/cache/nginx/proxy \
        /var/cache/nginx/proxy_temp \
        /var/lib/nginx \
        /var/log/nginx \
    \
    # Create the nginx user
    && addgroup -g 101 nginx \
    && adduser -u 101 -D -S -h /var/lib/nginx -s /sbin/nologin -G nginx nginx \
    \
    # Configure ownership and permissions of our nginx directories
    && chown -R nginx:nginx /var/cache/nginx /var/lib/nginx /var/log/nginx \
    && chmod -R 755 /var/cache/nginx \
    \
    # Install the AWS CLI, have to force install into system packages
    && pip install --break-system-packages --upgrade pip awscli \
    && apk -v --purge del py-pip

# Install the ngx_aws_token module, manually because LuaRocks bloats the image
ADD --chown=nginx:nginx \
        https://raw.githubusercontent.com/whitfin/ngx_aws_token/1.0/lua/ngx_aws_token.lua \
        /usr/local/openresty/lualib/ngx_aws_token.lua

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
