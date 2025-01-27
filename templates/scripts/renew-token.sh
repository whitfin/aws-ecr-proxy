#!/bin/sh
set -e

echo "Running: renew-token.sh"
# retry till new get new token
while true; do
  NEW_TOKEN=$(aws ecr get-login --no-include-email --region $AWS_REGION | awk '{ print $6 }')
  if [ ! -z "${ESC}{NEW_TOKEN}" ]; then
    break
  fi
  echo "Warning: unable to get new token, waiting before retry..."
  sleep 30
done
echo "Success: New token"
# convert the token into the base64 format we need to supply to nginx
NEW_TOKEN=$(echo AWS:${ESC}{NEW_TOKEN} | base64 | tr -d "[:space:]")

# Debugging
# echo "New token: ${ESC}{NEW_TOKEN}"

# create the token file with the new token to fix ecr tokens being too long
echo -n "Basic ${ESC}{NEW_TOKEN}" > $NGINX_CONFIG_DIR/token

# reload the nginx service if it was running
if test -f $NGINX_DIR/logs/nginx.pid; then
  nginx -s reload || echo "Warning: Failed to reload nginx"
  echo "Reloaded: nginx"
else
  echo "Warning: nginx not running"
fi