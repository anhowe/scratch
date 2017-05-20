#!/usr/bin/python
import base64
import os
import gzip
import StringIO
import sys

def convertToOneArmTemplateLine(clusterYamlFile):
    # remove the \r\n
    oneline="\\n".join(clusterYamlFile.split("\n"))
    oneline='\\"'.join(oneline.split('"'))
    return oneline

def usage():
    print
    print "    usage: %s file1" % os.path.basename(sys.argv[0])
    print
    print "    builds a one line custom data entry from the yaml file"
    print "    more files to /opt/azure"

if __name__ == "__main__":
    if len(sys.argv)!=2:
        usage()
        sys.exit(1)

    file = sys.argv[1]
    
    yml=""
    with open(file,'r') as f:
        yml = f.read()

    # convert yml file to one line
    oneline = convertToOneArmTemplateLine(yml)
    print '"customData": "[base64(\'%s\')]"' % (oneline)
