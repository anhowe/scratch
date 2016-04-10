#!/usr/bin/python
import base64
import os
import gzip
import StringIO
import sys

def CompressEncodeFile(file):
    # read the script file
    with open(file) as f:
        content = f.read()
    compressedbuffer=StringIO.StringIO()

    # gzip the script file
    with gzip.GzipFile(fileobj=compressedbuffer, mode='wb') as f:
        f.write(content)
    b64GzipStream=base64.b64encode(compressedbuffer.getvalue())

    return b64GzipStream

def usage():
    print
    print "    usage: %s file1" % os.path.basename(sys.argv[0])
    print
    print "    builds a one line custom data entry for writing a file"

if __name__ == "__main__":
    if len(sys.argv)!=2:
        usage()
        sys.exit(1)

    file = sys.argv[1]
    if not os.path.exists(file):
        print "Error: file %s does not exist"
        sys.exit(2)

    # build the yml file for cluster
    oneline = CompressEncodeFile(file)

    print '"customData": "%s"' % (oneline)
