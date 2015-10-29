#!/usr/bin/python
import base64
import os
import gzip
import StringIO
import sys

YAML_FILE = "customdata.yml"
CLUSTER_INSTALL_SCRIPT = "configure-mesos-cluster.sh"
CLUSTER_INSTALL_SCRIPT_GZ = "configure-mesos-cluster.sh.gz"

def cleanfiles():
    # delete the existing yaml file
    if os.path.exists(YAML_FILE):
        os.remove(YAML_FILE)

def buildClusterYMLFile():
    clustYamlFile="""#cloud-config

write_files:
 -  encoding: gzip
    content: !!binary |
        %s
    path: /opt/azure/containers/clusterinstall.sh
    permissions: '0744'

runcmd:
 - /bin/bash /opt/azure/containers/clusterinstall.sh arg1 arg2 arg3 > /var/log/azure/clusterinstall.log
"""
    
    # read the script file
    with open(CLUSTER_INSTALL_SCRIPT) as f:
        content = f.read()
    compressedbuffer=StringIO.StringIO()
    
    # gzip the script file
    with gzip.GzipFile(fileobj=compressedbuffer, mode='wb') as f:
        f.write(content)
    b64GzipStream=base64.b64encode(compressedbuffer.getvalue())
    
    # build the yaml file with base 64 gzip
    with open(YAML_FILE, 'w') as output:
        output.write(clustYamlFile % (b64GzipStream))
        
if __name__ == "__main__":
    # clean the files
    cleanfiles()
    
    # build the yml file for cluster
    buildClusterYMLFile()
    # build the yml file for devbox
    # build the ARM template for jumpboxless
    # build the ARM template for linux jumpbox
    # build the ARM template for windows jumpbox
    