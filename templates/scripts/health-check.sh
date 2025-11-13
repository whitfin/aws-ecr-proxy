#!/bin/sh
wget localhost:$PROXY_PORT/_health -q -O - > /dev/null 2>&1
