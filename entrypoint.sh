#!/bin/bash

syslogd &
postfix start

trap "postfix stop" SIGINT SIGTERM

while pidof master >/dev/null; do
  sleep 10
done
