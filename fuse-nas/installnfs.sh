#!/bin/bash

# variables that must be set beforehand
# FUSE_BASE=/blobfuse
# STORAGE_ACCOUNT=<storage_account_name>
# STORAGE_ACCOUNT_KEY=<storage_account_key>
# STORAGE_ACCOUNT_CONTAINER=<storage_account_container>
#

MOUNT_OPTIONS="noatime,nodiratime,nodev,noexec,nosuid,nofail"

function apt_get_update() {
    retries=10
    apt_update_output=/tmp/apt-get-update.out
    for i in $(seq 1 $retries); do
        timeout 120 apt-get update 2>&1 | tee $apt_update_output | grep -E "^([WE]:.*)|([eE]rr.*)$"
        [ $? -ne 0  ] && cat $apt_update_output && break || \
        cat $apt_update_output
        if [ $i -eq $retries ]; then
            return 1
        else sleep 30
        fi
    done
    echo Executed apt-get update $i times
}

function apt_get_install() {
    retries=$1; wait_sleep=$2; timeout=$3; shift && shift && shift
    for i in $(seq 1 $retries); do
        # timeout occasionally freezes
        #echo "timeout $timeout apt-get install --no-install-recommends -y ${@}"
        #timeout $timeout apt-get install --no-install-recommends -y ${@}
        apt-get install --no-install-recommends -y ${@}
        echo "completed"
        [ $? -eq 0  ] && break || \
        if [ $i -eq $retries ]; then
            return 1
        else
            sleep $wait_sleep
            apt_get_update
        fi
    done
    echo Executed apt-get install --no-install-recommends -y \"$@\" $i times;
}

function config_blobfuse() {
    # installation described: https://github.com/Azure/azure-storage-fuse/wiki/1.-Installation
	FUSE_DIR=/opt/azure-storage-fuse
    mkdir -p $FUSE_DIR
    cd $FUSE_DIR
    wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
    dpkg -i packages-microsoft-prod.deb
}

function config_linux() {
	#hostname=`hostname -s`
	#sudo sed -ie "s/127.0.0.1 localhost/127.0.0.1 localhost ${hostname}/" /etc/hosts
	export DEBIAN_FRONTEND=noninteractive  
	apt_get_update
	apt_get_install 20 10 180 nfs-kernel-server nfs-common blobfuse fuse
}

function configure_blobfuse_mount() {
    # configuration described: https://github.com/Azure/azure-storage-fuse/wiki/2.-Configuring-and-Running
    # write the files
    MOUNT_FILE=/root/mount.sh
    touch $MOUNT_FILE
    chmod 700 $MOUNT_FILE
    /bin/cat <<EOM >$MOUNT_FILE
#!/bin/bash
/usr/bin/blobfuse \$1 --tmp-path=/mnt/blobfusetmp -o allow_other -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 --config-file=/root/connection.cfg
EOM

    CREDS_FILE=/root/connection.cfg
    touch $CREDS_FILE
    chmod 600 $CREDS_FILE
    /bin/cat <<EOM >$CREDS_FILE
accountName ${STORAGE_ACCOUNT}
accountKey ${STORAGE_ACCOUNT_KEY}
containerName ${STORAGE_ACCOUNT_CONTAINER}
EOM

    # add the line to fstab
    mkdir -p ${FUSE_BASE}
    grep "${FUSE_BASE}" /etc/fstab >/dev/null 2>&1
    if [ ${?} -eq 0 ];
    then
        echo "Not adding ${FUSE_BASE} to fstab again (it's already there!)"
    else
        LINE="${MOUNT_FILE}\t${FUSE_BASE}\tfuse\t_netdev\t0 0"
        echo -e "${LINE}" >> /etc/fstab
    fi
    mount ${FUSE_BASE}
}

# export all the disks under ${DATA_BASE} for NFS
function configure_nfs() {
    # configure NFS export for the disk
    grep "^${FUSE_BASE}" /etc/exports > /dev/null 2>&1
    if [ $? = "0" ]; then
        echo "${FUSE_BASE} is already exported. Returning..."
    else
        echo -e "\n${FUSE_BASE}   *(rw,fsid=1,sync,no_root_squash)" >> /etc/exports
    fi
    
    systemctl enable nfs-kernel-server.service
    systemctl restart nfs-kernel-server.service
}

function main() {
    echo "config blob fuse"
    config_blobfuse

    echo "config Linux"
    config_linux

    #######################################################
    # remove this section once issue 213 is fixed https://github.com/Azure/azure-storage-fuse/issues/213
    echo "fix blobfuse issue 213 to allow writing through NFS"
    apt-get install pkg-config libfuse-dev cmake libcurl4-gnutls-dev libgnutls28-dev uuid-dev libgcrypt20-dev -y
    mkdir -p /opt/fuse
    cd /opt/fuse
    git clone https://github.com/anhowe/azure-storage-fuse.git
    cd azure-storage-fuse
    ./build.sh
    cp build/blobfuse /usr/bin/blobfuse
    #######################################################

    echo "config blob fuse mount"
    configure_blobfuse_mount

    echo "setup NFS Server"
    configure_nfs
    
    echo "installation complete"
}

main
