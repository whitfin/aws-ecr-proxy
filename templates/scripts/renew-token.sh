#!/bin/sh
set -e
echo "Renewing AWS ECR token..."

# retry till new get new token
while true; do
  TOKEN=$(aws ecr get-login --no-include-email --region $AWS_REGION | awk '{ print $6 }')
  if [ ! -z "${ESC}{TOKEN}" ]; then
    break
  fi
  echo "Warning: unable to get new token, waiting before retry..."
  sleep 30
done
echo "Successfully fetched new token"

# convert the token into the base64 format we need to supply to nginx
TOKEN=$(echo AWS:${ESC}{TOKEN} | base64 | tr -d "[:space:]")

# create the token file with the new token header
echo -n "Basic ${ESC}{TOKEN}" > $NGINX_CONFIG_DIR/.ecr-token

# reload the nginx service if it was running
if test -f $NGINX_DIR/logs/nginx.pid; then
  nginx -s reload
fi
