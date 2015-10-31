#!/usr/bin/python
import base64
import os
import gzip
import StringIO
import sys

def buildYMLFile(files):
    clusterYamlFile="""#cloud-config

write_files:
%s
"""
    writeFileBlock=""" -  encoding: gzip
        content: !!binary |
            %s
        path: /opt/azure/%s
        permissions: "0744"
"""
    filelines=""
    for encodeFile in files:
        # read the script file
        with open(encodeFile) as f:
            content = f.read()
        compressedbuffer=StringIO.StringIO()

        # gzip the script file
        with gzip.GzipFile(fileobj=compressedbuffer, mode='wb') as f:
            f.write(content)
        b64GzipStream=base64.b64encode(compressedbuffer.getvalue())
        filelines=filelines+(writeFileBlock % (b64GzipStream,encodeFile))

    return clusterYamlFile % (filelines)

def convertToOneArmTemplateLine(clusterYamlFile):
    # remove the \r\n
    oneline="\\n".join(clusterYamlFile.split("\n"))
    oneline='\\"'.join(oneline.split('"'))
    return oneline

def usage():
    print
    print "    usage: %s file1 file2 file3 . . ." % os.path.basename(sys.argv[0])
    print
    print "    builds a one line custom data entry for writing one or"
    print "    more files to /opt/azure"

if __name__ == "__main__":
    if len(sys.argv)==1:
        usage()
        sys.exit(1)

    files = sys.argv[1:]
    for file in files:
        if not os.path.exists(file):
            print "Error: file %s does not exist"
            sys.exit(2)

    # build the yml file for cluster
    yml = buildYMLFile(files)

    # convert yml file to one line
    oneline = convertToOneArmTemplateLine(yml)
    print '"customData": "[base64(\'%s\')]"' % (oneline)
