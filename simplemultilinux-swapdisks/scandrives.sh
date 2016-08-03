#!/bin/bash

PROGNAME=${0##*/}
AZUREUSER=azureuser

usage()
{
  cat << EO
Usage: $PROGNAME [options]

Manage the cluster.

Options:

Cluster Management
  --get-fstab          cat output of /etc/fstab
  --get-mounts         get device of / and /mnt
  --reboot-nodes       reboot all nodes (except this one)

Other
  --help                      show this output
EO
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

ARGS=$(getopt -s bash -o h --longoptions help,get-fstab,get-mounts,reboot-nodes --name $PROGNAME -- "$@")

if [ $? -ne 0 ] ; then
  usage
  exit 1
fi

eval set -- "$ARGS"

GETFSTAB=false
GETMOUNTS=false
REBOOTNODES=false

while true; do
  case $1 in
    -h|--help)
      usage
      exit 0
      ;;

    --get-fstab)
      shift
      GETFSTAB=true
      ;;

    --get-mounts)
      shift
      GETMOUNTS=true
      ;;

    --reboot-nodes)
      shift
      REBOOTNODES=true
      ;;

    --)
      shift
      break
      ;;

    *)
      echo "ERROR: invalid argument or missing parameter for $1"
      usage
      exit 1
  esac
done

installTools() {
  type pssh > /dev/null 2>&1
  if [ $? -ne 0 ] ; then
    sudo apt-get update && sudo apt-get install -y wget python ssh nmap
    sudo wget https://parallel-ssh.googlecode.com/files/pssh-2.3.1.tar.gz -O /tmp/pssh.tar.gz
    sudo tar xvf /tmp/pssh.tar.gz --directory /tmp
    cd /tmp/pssh-2.3.1 && sudo python setup.py install && cd -
    sudo rm -rf /tmp/*
  fi
}
installTools

getnodes() {
  if [ -e .nodes ] ; then
    cat .nodes
  else
    local -a arr=()
    RESULTS="$(nmap -sn 10.0.0.0/25 | grep report | awk '{print $5}')"
    while read -r line ; do
      arr=("${arr[@]}" "$line")
    done <<< "$RESULTS"
    local nodesString=$(declare -p arr | sed -e 's/^declare -a arr=//' | tee .nodes)
    local -a nodes=()
    eval "declare -a nodes=${nodesString}"
    for node in "${nodes[@]}"; do
      `ssh-keyscan -H $node >> ~/.ssh/known_hosts`
    done
    echo $nodesString
  fi
}

get-fstab() {
  local nodesString="$(getnodes)"
  local -a nodes=()
  eval "declare -a nodes=${nodesString}"

  for node in "${nodes[@]}"; do
    hostString="$hostString -H $AZUREUSER@$node"
  done
  pssh -i $hostString "ls -l /etc/fstab && sudo cat /etc/fstab"
}
if [ "$GETFSTAB" = true ] ; then
  get-fstab
  exit 0
fi

get-mounts() {
  local nodesString="$(getnodes)"
  local -a nodes=()
  eval "declare -a nodes=${nodesString}"

  for node in "${nodes[@]}"; do
    hostString="$hostString -H $AZUREUSER@$node"
  done
  pssh -i $hostString "mount | grep -e ' on /mnt ' -e ' on / '"
}
if [ "$GETMOUNTS" = true ] ; then
  get-mounts
  exit 0
fi

reboot-nodes() {
  local nodesString="$(getnodes)"
  local -a nodes=()
  eval "declare -a nodes=${nodesString}"

  me=`hostname -i`

  for node in "${nodes[@]}"; do
    if [ "$node" != $me ] ; then
      hostString="$hostString -H $AZUREUSER@$node"
    fi
  done
  pssh -i $hostString "sudo shutdown -r now"
}
if [ "$REBOOTNODES" = true ] ; then
  reboot-nodes
  exit 0
fi
