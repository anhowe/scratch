#!/bin/bash

# this script will continously reboot all machines on the cluster until the
# drives swap on at least 1 machine.

date
while true; do
  if /home/azureuser/scandrives.sh --get-mounts | grep -q sdb
  then
    echo "hit found"
    date
    break
  fi
  /home/azureuser/scandrives.sh --reboot-nodes > /dev/null
  sleep 30
done
/home/azureuser/scandrives.sh --get-mounts
