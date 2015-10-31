#!/usr/bin/python
import base64
import os
import gzip
import StringIO
import sys
import shutil

# Function reads a script file specified by installScriptPath from disk,
# and embeds it in a Yaml file as a base-64 enconded string to be
# executed later by template
def buildYamlFileWithScriptFile(installScriptPath):
    gzipBuffer=StringIO.StringIO()
    
    clusterYamlFile="""#cloud-config

write_files:
 -  encoding: gzip
    content: !!binary |
        %s
    path: /opt/azure/containers/%s
    permissions: "0744"
"""
    with open(installScriptPath) as scriptFile:
        content = scriptFile.read()

    with gzip.GzipFile(fileobj=gzipBuffer, mode='wb') as gzipWriter:
        gzipWriter.write(content)

    b64GzipStream=base64.b64encode(gzipBuffer.getvalue())
    
    return clusterYamlFile % (b64GzipStream, installScriptPath)
    
# processes a Yaml file to be included properly in ARM template
def convertToOneArmTemplateLine(clusterYamlFile):
    # remove the \r\n and include \n in body
    oneline = "\\n".join(clusterYamlFile.split("\n"))
    # Escape " to \"
    return '\\"'.join(oneline.split('"'))

# Loads the base ARM template file and injects the Yaml for the shell scripts into it.
def processBaseTemplate(baseTemplatePath, jumpboxTemplatePath):
    # Shell Scripts to load into YAML
    MESOS_CLUSTER_INSTALL_SCRIPT = "configure-mesos-cluster.sh"
    LINUX_JUMPBOX_INSTALL_SCRIPT = "configure-ubuntu.sh"

    #String to replace in JSON file
    CLUSTER_YAML_REPLACE_STRING  = "#clusterCustomDataInstallYaml"
    JUMPBOX_FRAGMENT_REPLACE_STRING = "#jumpboxFragment"
    JUMPBOX_FQDN_REPLACE_STRING = "#jumpboxFQDN"
    JUMPBOX_LINUX_YAML_REPLACE_STRING = "#jumpboxLinuxCustomDataInstallYaml"
    
    armTemplate = []
    with open(baseTemplatePath) as f:
        armTemplate = f.read()
    
    # Generate cluster Yaml file for ARM
    clusterYamlFile = convertToOneArmTemplateLine(buildYamlFileWithScriptFile(MESOS_CLUSTER_INSTALL_SCRIPT))
    armTemplate = clusterYamlFile.join(armTemplate.split(CLUSTER_YAML_REPLACE_STRING))
    
    # Generate jumpbox Yaml file for ARM
    linuxJumpboxYamlFile = convertToOneArmTemplateLine(buildYamlFileWithScriptFile(LINUX_JUMPBOX_INSTALL_SCRIPT))
    armTemplate = linuxJumpboxYamlFile.join(armTemplate.split(JUMPBOX_LINUX_YAML_REPLACE_STRING))
    
    # Add Jumpbox ARM and FQDN Fragment if jumpboxTemplatePath is defined
    jumpboxTemplate = ""
    jumpboxFQDN = ""
    
    if jumpboxTemplatePath != None :
        # Add Jumpbox FQDN Fragment if jumpboxTemplatePath is defined
        jumpboxFQDN = "[reference(concat('Microsoft.Network/publicIPAddresses/', parameters('applicationEndpointDNSNamePrefix'))).dnsSettings.fqdn]"
        with open(jumpboxTemplatePath) as f:
            jumpboxTemplate = f.read()
                
    armTemplate = jumpboxTemplate.join(armTemplate.split(JUMPBOX_FRAGMENT_REPLACE_STRING))
    armTemplate = jumpboxFQDN.join(armTemplate.split(JUMPBOX_FQDN_REPLACE_STRING))
        
    return armTemplate;

if __name__ == "__main__":
    # Input Arm Template Artifacts to be processed in
    # Note:  These files are not useable ARM templates on thier own.  
    # They require processing by this script.
    ARM_INPUT_TEMPLATE_TEMPLATE        = "base-template.json"
    ARM_INPUT_PARAMETER_TEMPLATE       = "base-template.parameters.json"
    ARM_INPUT_WINDOWS_JUMPBOX_TEMPLATE = "fragment-windows-jumpbox.json"
    ARM_INPUT_LINUX_JUMPBOX_TEMPLATE   = "fragment-linux-jumpbox.json"

    # Output ARM Template Files.  WIll Also Output name.parameters.json for each
    ARM_OUTPUT_TEMPLATE                    = "mesos-cluster.json"
    ARM_OUTPUT_TEMPLATE_WINDOWS_JUMPBOX    = "mesos-cluster-with-windows-jumpbox.json"
    ARM_OUTPUT_TEMPLATE_LINUX_JUMPBOX      = "mesos-cluster-with-linux-jumpbox.json"
   
    # build the ARM template for jumpboxless
    with open(ARM_OUTPUT_TEMPLATE, "w") as armTemplate:
        clusterTemplate = processBaseTemplate(ARM_INPUT_TEMPLATE_TEMPLATE, None)
        armTemplate.write(clusterTemplate)
        shutil.copyfile(ARM_INPUT_PARAMETER_TEMPLATE, ".parameters.json".join(ARM_OUTPUT_TEMPLATE.split(".json")) )
        
    # build the ARM template for linux jumpbox
    with open(ARM_OUTPUT_TEMPLATE_LINUX_JUMPBOX, "w") as armTemplate:
        clusterTemplate = processBaseTemplate(ARM_INPUT_TEMPLATE_TEMPLATE, ARM_INPUT_LINUX_JUMPBOX_TEMPLATE )
        armTemplate.write(clusterTemplate)
        shutil.copyfile(ARM_INPUT_PARAMETER_TEMPLATE, ".parameters.json".join(ARM_OUTPUT_TEMPLATE_LINUX_JUMPBOX.split(".json")) )
    
    # build the ARM template for windows jumpbox
    with open(ARM_OUTPUT_TEMPLATE_WINDOWS_JUMPBOX, "w") as armTemplate:
        clusterTemplate = processBaseTemplate(ARM_INPUT_TEMPLATE_TEMPLATE, ARM_INPUT_WINDOWS_JUMPBOX_TEMPLATE)
        armTemplate.write(clusterTemplate)
        shutil.copyfile(ARM_INPUT_PARAMETER_TEMPLATE, ".parameters.json".join(ARM_OUTPUT_TEMPLATE_WINDOWS_JUMPBOX.split(".json")) )