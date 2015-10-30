#!/usr/bin/python
import base64
import os
import gzip
import StringIO
import sys

CLUSTER_INSTALL_SCRIPT = "configure-mesos-cluster.sh"
CLUSTER_INSTALL_SCRIPT_GZ = "configure-mesos-cluster.sh.gz"
ARM_TEMPLATE_TEMPLATE = "azuredeploy.json"
ARM_WINDOWS_TEMPLATE = "../azuredeploy.winjb.json"
CLUSTER_YAML_REPLACE_STRING = "customDataClusterInstallYamlToReplace"

def buildClusterYMLFile():
    clusterYamlFile="""#cloud-config

write_files:
 -  encoding: gzip
    content: !!binary |
        %s
    path: /opt/azure/containers/clusterinstall.sh
    permissions: "0744"
"""
    
    # read the script file
    with open(CLUSTER_INSTALL_SCRIPT) as f:
        content = f.read()
    compressedbuffer=StringIO.StringIO()
    
    # gzip the script file
    with gzip.GzipFile(fileobj=compressedbuffer, mode='wb') as f:
        f.write(content)
    b64GzipStream=base64.b64encode(compressedbuffer.getvalue())
    
    return clusterYamlFile % (b64GzipStream)
    
def convertToOneArmTemplateLine(clusterYamlFile):
    # remove the \r\n
    return "\\n".join(clusterYamlFile.split("\n"))

def buildArmTemplateWindowsJumpbox(oneArmYamlFile):
    armTemplate = []
    with open(ARM_TEMPLATE_TEMPLATE) as f:
        armTemplate = f.read()
    
    # global replacement of the YAML string
    armTemplate = oneArmYamlFile.join(armTemplate.split(CLUSTER_YAML_REPLACE_STRING))
    
    with open(ARM_WINDOWS_TEMPLATE, "w") as f:
        f.write(armTemplate)

if __name__ == "__main__":
    # build the yml file for cluster
    clusterYamlFile = buildClusterYMLFile()
    
    # convert yml file to one line
    oneArmYamlFile = convertToOneArmTemplateLine(clusterYamlFile)
    
    # build the yml file for devbox
    # build the ARM template for jumpboxless
    # build the ARM template for linux jumpbox
    # build the ARM template for windows jumpbox
    buildArmTemplateWindowsJumpbox(oneArmYamlFile)
    
    