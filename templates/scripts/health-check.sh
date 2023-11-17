#!/bin/sh
wget localhost:$PROXY_PORT/health -q -O - > /dev/null 2>&1
