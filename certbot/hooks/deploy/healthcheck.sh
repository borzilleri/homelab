#!/usr/bin/env sh

HEALTHCHECK_ID="UUID OR PING-KEY/SLUG HERE"

curl -fsS -m 10 --retry 5 -o /dev/null \
  "https://hc-ping.com/$HEALTHCHECK_ID"