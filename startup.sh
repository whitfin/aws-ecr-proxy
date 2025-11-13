#!/bin/sh
set -e

# default values for the AWS vars
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-''}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-''}

# default values for the nginx config
export NGINX_DIR=/usr/local/openresty/nginx
export NGINX_CONFIG_DIR=$NGINX_DIR/conf

# default values for the proxy config
export PROXY_PORT=${PROXY_PORT:-'5000'}
export PROXY_CACHE_KEY=${PROXY_CACHE_KEY:-'$uri'}
export PROXY_CACHE_LIMIT=${PROXY_CACHE_LIMIT:-'64g'}
export PROXY_DNS_RESOLVER=${PROXY_DNS_RESOLVER:-'8.8.8.8'}
export PROXY_NAMESPACE_PATTERN=${PROXY_NAMESPACE_PATTERN:-".*"}
export PROXY_WORKER_PROCESSES=${PROXY_WORKER_PROCESSES:-"1"}

# obviously we need the proxy endpoint
if [ -z "$PROXY_ECR_ENDPOINT" ] ; then
  echo "PROXY_ECR_ENDPOINT must be provided."
  exit 1
fi


# handle SSL configuration properties if we have both key + cert
if [ "$PROXY_SSL_KEY" ] && [ "$PROXY_SSL_CERTIFICATE" ]; then
  export PROXY_LISTENER_SCHEME="https"
  export PROXY_LISTENER_OPTIONS="ssl $PROXY_LISTENER_OPTIONS"
else
  export PROXY_LISTENER_SCHEME="http"
  export PROXY_LISTENER_OPTIONS=""
fi

# fetch the current environment variables for replacement
EXPORTED_VARIABLES="$(env | cut -d= -f1 | sed 's/.*/\$&/')"

# run through our replacement of environment variables in the files
for config in $(find /templates -type f -print | cut -d'/' -f3-)
do
    mkdir -p $(dirname $config)
    envsubst "$EXPORTED_VARIABLES" < /templates/$config > $config
done

# drop the ssl configuration if disabled
if [ "$PROXY_LISTENER_SCHEME" == "http" ]; then
  rm $NGINX_CONFIG_DIR/server/certs.conf
fi

# verify that we have a valid AWS session
if ! aws sts get-caller-identity > /dev/null 2>&1; then
  echo "Unable to verify AWS credentials, please check your configuration."
  exit 1
fi

# cmd
exec "$@"
