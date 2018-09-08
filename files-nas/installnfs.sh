#!/bin/bash

# variables that must be set beforehand
# NFS_BASE=/blobfuse
# STORAGE_ACCOUNT=<storage_account_name>
# STORAGE_ACCOUNT_KEY=<storage_account_key>
# STORAGE_ACCOUNT_SHARE=<STORAGE_ACCOUNT_SHARE>
#

CONVMVFS_MOUNT=${NFS_BASE}conv

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

function config_linux() {
	#hostname=`hostname -s`
	#sudo sed -ie "s/127.0.0.1 localhost/127.0.0.1 localhost ${hostname}/" /etc/hosts
	export DEBIAN_FRONTEND=noninteractive  
	apt_get_update
	apt_get_install 20 10 180 nfs-kernel-server nfs-common cifs-utils fuse-convmvfs
}

function configure_files_mount() {
    # configuration described: https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-linux
    mkdir -p /etc/smbcredentials
    CREDFILE=/etc/smbcredentials/${STORAGE_ACCOUNT}.cred
    if [ ! -f "${CREDFILE}" ]; then
        touch ${CREDFILE}
        chmod 600 ${CREDFILE}
        echo "username=${STORAGE_ACCOUNT}" >> ${CREDFILE}
        echo "password=${STORAGE_ACCOUNT_KEY}" >> ${CREDFILE}
    fi

    # add the line to fstab
    mkdir -p ${NFS_BASE}
    chown nobody:nogroup ${NFS_BASE}
    grep "${NFS_BASE}" /etc/fstab >/dev/null 2>&1
    if [ ${?} -eq 0 ];
    then
        echo "Not adding ${NFS_BASE} to fstab again (it's already there!)"
    else
        echo "//${STORAGE_ACCOUNT}.file.core.windows.net/${STORAGE_ACCOUNT_SHARE} ${NFS_BASE} cifs nofail,vers=3.0,credentials=${CREDFILE},dir_mode=0777,file_mode=0777,serverino" >> /etc/fstab
    fi
    mount ${NFS_BASE}
}

function configure_convmvfs_mount() {
    # configuration described in the answer here https://unix.stackexchange.com/questions/315637/is-it-possible-to-create-a-nfs-share-from-a-cifs-mounted-directory
    
    # write the files
    MOUNT_FILE=/root/mount.sh
    touch $MOUNT_FILE
    chmod 700 $MOUNT_FILE
    /bin/cat <<EOM >$MOUNT_FILE
#!/bin/bash
/usr/bin/convmvfs \$1 -o srcdir=${NFS_BASE},icharset=iso-8859-1,ocharset=iso-8859-1,user_allow_other
EOM

    # add the line to fstab
    mkdir -p ${CONVMVFS_MOUNT}
    grep "${CONVMVFS_MOUNT}" /etc/fstab >/dev/null 2>&1
    if [ ${?} -eq 0 ];
    then
        echo "Not adding ${CONVMVFS_MOUNT} to fstab again (it's already there!)"
    else
        LINE="${MOUNT_FILE}\t${CONVMVFS_MOUNT}\tfuse\t_netdev\t0 0"
        echo -e "${LINE}" >> /etc/fstab
    fi
    mount ${CONVMVFS_MOUNT}
}

# export all the disks under ${DATA_BASE} for NFS
function configure_nfs() {
    # configure NFS export for the disk
    grep "^${CONVMVFS_MOUNT}" /etc/exports > /dev/null 2>&1
    if [ $? = "0" ]; then
        echo "${CONVMVFS_MOUNT} is already exported. Returning..."
    else
        echo -e "\n${CONVMVFS_MOUNT}   *(rw,fsid=1,sync,no_root_squash)" >> /etc/exports
    fi
    
    systemctl enable nfs-kernel-server.service
    systemctl restart nfs-kernel-server.service
}

function main() {
    echo "config Linux"
    config_linux

    echo "config files mount"
    configure_files_mount

    echo "config convmvfs mount"
    configure_convmvfs_mount

    echo "setup NFS Server"
    configure_nfs
    
    echo "installation complete"
}

main
