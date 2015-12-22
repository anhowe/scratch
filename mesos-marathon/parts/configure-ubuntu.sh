#!/bin/bash

set -x

echo "starting ubuntu devbox install on pid $$"
date
ps axjf

#############
# Parameters
#############

AZUREUSER=$1
MASTERCOUNT=$3
MASTERINITIALADDR=$2
HOMEDIR="/home/$AZUREUSER"
VMNAME=`hostname`
echo "User: $AZUREUSER"
echo "User home dir: $HOMEDIR"
echo "vmname: $VMNAME"
echo "Num of Masters:$MASTERCOUNT"
echo "Master Initial Addr: $MASTERINITIALADDR"


###################
# Common Functions
###################

#grant access to azure directory to check jumpbox-bootstrap.log file
sudo chmod 777 /var/log/azure/

ensureAzureNetwork()
{
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
    echo "the network is not healthy, aborting install"
    ifconfig
    ip a
    exit 2
  fi
}
ensureAzureNetwork

################
# Install Docker
################

echo "Installing and configuring docker and swarm"

time wget -qO- https://get.docker.com | sh

# Start Docker and listen on :2375 (no auth, but in vnet)
echo 'DOCKER_OPTS="-H unix:///var/run/docker.sock -H 0.0.0.0:2375"' | sudo tee /etc/default/docker
# the following insecure registry is for OMS
echo 'DOCKER_OPTS="$DOCKER_OPTS --insecure-registry 137.135.93.9"' | sudo tee -a /etc/default/docker
sudo service docker restart

ensureDocker()
{
  # ensure that docker is healthy
  dockerHealthy=1
  for i in {1..3}; do
    sudo docker info
    if [ $? -eq 0 ]
    then
      # hostname has been found continue
      dockerHealthy=0
      echo "Docker is healthy"
      sudo docker ps -a
      break
    fi
    sleep 10
  done
  if [ $dockerHealthy -ne 0 ]
  then
    echo "Docker is not healthy"
  fi
}
ensureDocker

###################################################
# Update Ubuntu and install all necessary binaries
###################################################

time sudo apt-get -y update
# kill the waagent and uninstall, otherwise, adding the desktop will do this and kill this script
sudo pkill waagent
time sudo apt-get -y remove walinuxagent
time sudo DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install ubuntu-desktop firefox vnc4server ntp nodejs npm expect gnome-panel gnome-settings-daemon metacity nautilus gnome-terminal gnome-core

#########################################
# Setup Azure User Account including VNC
#########################################
sudo -i -u $AZUREUSER mkdir $HOMEDIR/bin
sudo -i -u $AZUREUSER touch $HOMEDIR/bin/startvnc
sudo -i -u $AZUREUSER chmod 755 $HOMEDIR/bin/startvnc
sudo -i -u $AZUREUSER touch $HOMEDIR/bin/stopvnc
sudo -i -u $AZUREUSER chmod 755 $HOMEDIR/bin/stopvnc
echo "vncserver -geometry 1280x1024 -depth 16" | sudo tee $HOMEDIR/bin/startvnc
echo "vncserver -kill :1" | sudo tee $HOMEDIR/bin/stopvnc
echo "export PATH=\$PATH:~/bin" | sudo tee -a $HOMEDIR/.bashrc

prog=/usr/bin/vncpasswd
mypass="password"

sudo -i -u $AZUREUSER /usr/bin/expect <<EOF
spawn "$prog"
expect "Password:"
send "$mypass\r"
expect "Verify:"
send "$mypass\r"
expect eof
exit
EOF

sudo -i -u $AZUREUSER startvnc
sudo -i -u $AZUREUSER stopvnc

echo "#!/bin/sh" | sudo tee $HOMEDIR/.vnc/xstartup
echo "" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "export XKL_XMODMAP_DISABLE=1" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "unset SESSION_MANAGER" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "unset DBUS_SESSION_BUS_ADDRESS" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "xsetroot -solid grey" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "vncconfig -iconic &" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "gnome-panel &" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "gnome-settings-daemon &" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "metacity &" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "nautilus &" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "gnome-terminal &" | sudo tee -a $HOMEDIR/.vnc/xstartup

sudo -i -u $AZUREUSER $HOMEDIR/bin/startvnc

#####################
# setup the Azure CLI
#####################
time sudo npm install azure-cli -g
time sudo update-alternatives --install /usr/bin/node nodejs /usr/bin/nodejs 100

####################
# Setup Chrome
####################
cd /tmp
time wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
time sudo dpkg -i google-chrome-stable_current_amd64.deb
time sudo apt-get -y --force-yes install -f
time rm /tmp/google-chrome-stable_current_amd64.deb

###################
# Install Java 
###################
sudo apt-get -y install openjdk-7-jre-headless

###################
# Install pip & setup dcos directory 
###################
sudo apt-get install -y python-pip

sudo pip install virtualenv

mkdir $HOMEDIR/dcos
sudo chown $AZUREUSER $HOMEDIR/dcos
cd $HOMEDIR/dcos
wget https://raw.githubusercontent.com/mesosphere/dcos-cli/master/bin/install/install-optout-dcos-cli.sh
bash ./install-optout-dcos-cli.sh . http://master.mesos --add-path yes

# add DCOS_CONFIG env variable for DCOS CAssandra subcommands
echo DCOS_CONFIG=/home/$AZUREUSER/.dcos/dcos.toml > /home/$AZUREUSER/.bashrc

########################################
# generate nameserver IPs for resolvconf/resolv.conf.d/head file
# for mesos_dns so service names can be resolve from the jumpbox as well
########################################

 for ((i=MASTERINITIALADDR; i<MASTERINITIALADDR+MASTERCOUNT; i++)); do
    echo "nameserver 10.0.0.$i" | sudo tee -a /etc/resolvconf/resolv.conf.d/head
  done
echo "/etc/resolvconf/resolv.conf.d/head"  
cat   /etc/resolvconf/resolv.conf.d/head
sudo service resolvconf restart

# AZUREUSER can run docker without sudo
sudo usermod -aG docker $AZUREUSER

date
echo "completed ubuntu devbox install on pid $$"
