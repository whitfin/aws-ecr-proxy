#!/bin/sh
set -e

# default values for the aws config
export AWS_INSTANCE_AUTH=${AWS_INSTANCE_AUTH:-'false'}

# default values for the nginx config
export NGINX_DIR=/usr/local/openresty/nginx
export NGINX_CONFIG_DIR=$NGINX_DIR/conf

# default values for the proxy config
export PROXY_PORT=${PROXY_PORT:-'5000'}
export PROXY_CACHE_KEY=${PROXY_CACHE_KEY:-'$uri'}
export PROXY_CACHE_LIMIT=${PROXY_CACHE_LIMIT:-'64g'}
export PROXY_DNS_RESOLVER=${PROXY_DNS_RESOLVER:-'8.8.8.8'}
export PROXY_NAMESPACE_PATTERN=${PROXY_NAMESPACE_PATTERN:-".*"}

# obviously we need the proxy endpoint
if [ -z "$PROXY_ECR_ENDPOINT" ] ; then
  echo "PROXY_ECR_ENDPOINT must be provided."
  exit 1
fi

# we also need the endpoints region
if [ -z "$AWS_REGION" ] ; then
  echo "AWS_REGION must be provided."
  exit 1
fi

# we need at least one form of AWS authentication
if [ "$AWS_INSTANCE_AUTH" != "true" ]; then
  if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY must be provided."
    exit 1
  fi
fi

# handle SSL configuration properties if we have both key + cert
if [ "$PROXY_SSL_KEY" ] && [ "$PROXY_SSL_CERTIFICATE"]; then
  export PROXY_LISTENER_SCHEME="https"
  export PROXY_LISTENER_OPTIONS="ssl $PROXY_LISTENER_OPTIONS"
else
  export PROXY_LISTENER_SCHEME="http"
fi

# run through our replacement of environment variables in the files
for config in $(find /templates -type f -print | cut -d'/' -f3-)
do
    mkdir -p $(dirname $config)
    cat /templates/$config | ESC='$' envsubst > $config
done

# drop the ssl configuration if disabled
if [ "$PROXY_LISTENER_SCHEME" == "http" ]; then
  rm $NGINX_CONFIG_DIR/server/ssl.conf
fi

# drop the credentials file if we're going to use the
if [ "$AWS_INSTANCE_AUTH" == "true" ]; then
  rm /root/.aws/credentials
fi

# add the auth token in default.conf
sh /scripts/renew-token.sh

# cmd
exec "$@"
