#!/usr/bin/python
import base64
import os
import gzip
import StringIO
import sys
import shutil
import json
import argparse

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
    # remove the \r\n and include \n in body and escape " to \"
    return  clusterYamlFile.replace("\n", "\\n").replace('"', '\\"')

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
    armTemplate = armTemplate.replace(CLUSTER_YAML_REPLACE_STRING, clusterYamlFile)

    # Add Jumpbox YAML, ARM and FQDN Fragment if jumpboxTemplatePath is defined
    jumpboxTemplate = ""
    jumpboxFQDN = ""
    linuxJumpboxYamlFile = ""
    
    if jumpboxTemplatePath != None :
        # Add Jumpbox FQDN Fragment if jumpboxTemplatePath is defined
        jumpboxFQDN = "[reference(concat('Microsoft.Network/publicIPAddresses/', variables('jumpboxEndpointDNSNamePrefix'))).dnsSettings.fqdn]"
        
        # Generate jumpbox Yaml file for ARM
        linuxJumpboxYamlFile = convertToOneArmTemplateLine(buildYamlFileWithScriptFile(LINUX_JUMPBOX_INSTALL_SCRIPT))
        with open(jumpboxTemplatePath) as f:
            jumpboxTemplate = f.read()
    
    # Want these to be replaced with blank strings if jumpboxTemplatePath is None

    armTemplate = armTemplate.replace(JUMPBOX_FRAGMENT_REPLACE_STRING, jumpboxTemplate)
    armTemplate = armTemplate.replace(JUMPBOX_FQDN_REPLACE_STRING, jumpboxFQDN)
    armTemplate = armTemplate.replace(JUMPBOX_LINUX_YAML_REPLACE_STRING, linuxJumpboxYamlFile)
    
    # Make sure the final string is valid JSON
    try:
        json_object = json.loads(armTemplate)
    except ValueError, e:
        print e
        errorFileName = baseTemplatePath + ".err"
        with open(errorFileName, "w") as f:
            f.write(armTemplate)
        print "Invalid armTemplate saved to: " + errorFileName
        raise
        
    return armTemplate;

if __name__ == "__main__":
    # Parse Arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("-o", "--output_directory",  help="Directory to write templates files to.  Default is current directory.")
    parser.add_argument("-wapf", "--write_parameter_files", help="Write separate parameter file for each template.  Default is false.",
                        action="store_true" )
    
    args = parser.parse_args()
    
    if (args.output_directory == None) :
        args.output_directory = os.getcwd()
        
    args.output_directory = os.path.expandvars(os.path.normpath(args.output_directory))
    
    if ( os.path.exists(args.output_directory) == False ):
        os.mkdir(args.output_directory)
    
    # Input Arm Template Artifacts to be processed in
    # Note:  These files are not useable ARM templates on thier own.  
    # They require processing by this script.
    ARM_INPUT_TEMPLATE_TEMPLATE        = "base-template.json"
    ARM_INPUT_PARAMETER_TEMPLATE       = "base-template.parameters.json"
    ARM_INPUT_WINDOWS_JUMPBOX_TEMPLATE = "fragment-windows-jumpbox.json"
    ARM_INPUT_LINUX_JUMPBOX_TEMPLATE   = "fragment-linux-jumpbox.json"

    # Output ARM Template Files.  WIll Also Output name.parameters.json for each
    ARM_OUTPUT_TEMPLATE                    = "mesos-cluster-with-no-jumpbox.json"
    ARM_OUTPUT_TEMPLATE_WINDOWS_JUMPBOX    = "mesos-cluster-with-windows-jumpbox.json"
    ARM_OUTPUT_TEMPLATE_LINUX_JUMPBOX      = "mesos-cluster-with-linux-jumpbox.json"
       
    # build the ARM template for jumpboxless
    with open(os.path.join(args.output_directory, ARM_OUTPUT_TEMPLATE), "w") as armTemplate:
        clusterTemplate = processBaseTemplate(ARM_INPUT_TEMPLATE_TEMPLATE, None)
        armTemplate.write(clusterTemplate)
        
    # build the ARM template for linux jumpbox
    with open(os.path.join(args.output_directory,ARM_OUTPUT_TEMPLATE_LINUX_JUMPBOX), "w") as armTemplate:
        clusterTemplate = processBaseTemplate(ARM_INPUT_TEMPLATE_TEMPLATE, ARM_INPUT_LINUX_JUMPBOX_TEMPLATE )
        armTemplate.write(clusterTemplate)
    
    # build the ARM template for windows jumpbox
    with open(os.path.join(args.output_directory, ARM_OUTPUT_TEMPLATE_WINDOWS_JUMPBOX), "w") as armTemplate:
        clusterTemplate = processBaseTemplate(ARM_INPUT_TEMPLATE_TEMPLATE, ARM_INPUT_WINDOWS_JUMPBOX_TEMPLATE)
        armTemplate.write(clusterTemplate)
        
    # Write parameter files if specified
    if (args.write_parameter_files == True) :
        shutil.copyfile(ARM_INPUT_PARAMETER_TEMPLATE, ARM_OUTPUT_TEMPLATE.replace(".json", ".parameters.json") )
        shutil.copyfile(ARM_INPUT_PARAMETER_TEMPLATE, ARM_OUTPUT_TEMPLATE_LINUX_JUMPBOX.replace(".json", ".parameters.json") )
        shutil.copyfile(ARM_INPUT_PARAMETER_TEMPLATE, ARM_OUTPUT_TEMPLATE_WINDOWS_JUMPBOX.replace(".json", ".parameters.json") )