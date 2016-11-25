#!/bin/bash

syslogd &
postfix start

trap "postfix stop" SIGINT SIGTERM

while postfix status 2>/dev/null; do
  sleep 10
done
