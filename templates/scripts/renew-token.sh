#!/bin/sh
set -e
echo "Renewing AWS ECR token..."

# retry till new get new token
while true; do
  TOKEN=$(aws ecr get-authorization-token --region $AWS_REGION --query 'authorizationData[*].authorizationToken' --output text)
  if [ ! -z "${ESC}{TOKEN}" ]; then
    break
  fi
  echo "Warning: unable to get new token, waiting before retry..."
  sleep 30
done
echo "Successfully fetched new token"

# create the token file with the new token header
echo -n "Basic ${ESC}TOKEN" > $NGINX_CONFIG_DIR/.ecr-token

# reload the nginx service if it was running
if test -f $NGINX_DIR/logs/nginx.pid; then
  nginx -s reload
fi
