#!/bin/sh
set -e

# locate the existing auth token stored inside the nginx configuration
EXISTING_TOKEN=$(grep X-Forwarded-User $NGINX_CONFIG_DIR/nginx.conf)
EXISTING_TOKEN=$(echo ${ESC}{EXISTING_TOKEN} | awk '{ print $4 }' | uniq | tr -d "\n\r")

# retry till new get new token
while true; do
  NEW_TOKEN=$(aws ecr get-login --no-include-email | awk '{ print $6 }')
  if [ ! -z "${ESC}{NEW_TOKEN}" ]; then
    break
  fi
  echo "Warning: unable to get new token, waiting before retry..."
  sleep 30
done

# convert the token into the base64 format we need to supply to nginx
NEW_TOKEN=$(echo AWS:${ESC}{NEW_TOKEN} | base64 | tr -d "[:space:]")

# replace the existing token with the new token we retrieved from AWS in the config
sed -i "s|${ESC}{EXISTING_TOKEN%??}|${ESC}{NEW_TOKEN}|g" $NGINX_CONFIG_DIR/nginx.conf

# reload the nginx service if it was runnign
if test -f $NGINX_DIR/logs/nginx.pid; then
  nginx -s reload
fi
