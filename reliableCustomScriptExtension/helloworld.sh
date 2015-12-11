#!/bin/bash

#######################################
# wait for network to become ready
#######################################
ensureAzureNetwork()
{
  VMNAME=`hostname`
  # ensure the host name is resolvable
  hostResolveHealthy=1
  for i in {1..120}; do
    host $VMNAME
    if [ $? -eq 0 ]
    then
      # hostname has been found continue
      hostResolveHealthy=0
      echo "the host name resolves"
      break
    fi
    sleep 1
  done
  if [ $hostResolveHealthy -ne 0 ]
  then
    echo "host name does not resolve, aborting install"
    exit 1
  fi

  # ensure the network works
  networkHealthy=1
  for i in {1..12}; do
    wget -O/dev/null http://bing.com
    if [ $? -eq 0 ]
    then
      # hostname has been found continue
      networkHealthy=0
      echo "the network is healthy"
      break
    fi
    sleep 10
  done
  if [ $networkHealthy -ne 0 ]
  then
    echo "the network is not healthy, cannot download from bing, aborting install"
    ifconfig
    ip a
    exit 2
  fi
  # ensure the hostname -i works
  networkHealthy=1
  for i in {1..120}; do
    hostname -i
    if [ $? -eq 0 ]
    then
      # hostname has been found continue
      networkHealthy=0
      echo "the network is healthy"
      break
    fi
    sleep 1
  done
  if [ $networkHealthy -ne 0 ]
  then
    echo "the network is not healthy, cannot resolve ip address, aborting install"
    ifconfig
    ip a
    exit 2
  fi
  # ensure hostname -f works
  networkHealthy=1
  for i in {1..120}; do
    hostname -f
    if [ $? -eq 0 ]
    then
      # hostname has been found continue
      networkHealthy=0
      echo "the network is healthy"
      break
    fi
    sleep 1
  done
  if [ $networkHealthy -ne 0 ]
  then
    echo "the network is not healthy, cannot resolve hostname, aborting install"
    ifconfig
    ip a
    exit 2
  fi
}
ensureAzureNetwork

#######################################
# run the main program
#######################################
echo hello world
