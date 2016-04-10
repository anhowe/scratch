#!/usr/bin/python
import base64
import os
import gzip
import re
import StringIO
import sys

# goal "commandToExecute": "[variables('jumpboxWindowsCustomScript')]"

def convertToOneArmTemplateLine(file):
    with open(file) as f:
        content = f.read()

    oneline=" ; ".join(content.split("\n"))
    oneline="'".join(oneline.split('"'))

    codeRegEx=re.compile(r".arguments\s*=\s*'([^']*)'\s*;")
    matchArray=codeRegEx.findall(oneline)
    if len(matchArray)>1:
        print oneline
        raise AssertionError, "incorrect number of matches"
    argumentList=''
    if len(matchArray) == 1:
        argumentList = matchArray[0]
    oneline=codeRegEx.sub('',oneline)

    return oneline,argumentList

def usage():
    print
    print "    usage: %s file1" % os.path.basename(sys.argv[0])
    print
    print "    builds a one line string to send to commandToExecute"

if __name__ == "__main__":
    if len(sys.argv)!=2:
        usage()
        sys.exit(1)

    file = sys.argv[1]
    if not os.path.exists(file):
        print "Error: file %s does not exist"
        sys.exit(2)

    # build the yml file for cluster
    oneline, argumentList = convertToOneArmTemplateLine(file)

    print "copy/paste the following rows into your templates variables and use"
    print "[variables('windowsCustomScript')] as the commandToExecute in your"
    print "custom script extension"
    print
    print '"windowsCustomScriptArguments": "$arguments = \'%s\' ; ",' % (argumentList)
    print '"windowsCustomScriptSuffix": "%s",' % (oneline)
    print '"windowsCustomScript": "[concat(\'powershell.exe -ExecutionPolicy Unrestricted -command \\"\', variables(\'windowsCustomScriptArguments\'), variables(\'windowsCustomScriptSuffix\'), \'\\"\')]",'
    #print '"commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -command \\"%s\\""' % (oneline)
