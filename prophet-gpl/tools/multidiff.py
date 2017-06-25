#!/usr/bin/env python
import subprocess
from sys import argv

ref = argv[1];
for filename in argv[2:]:
    ret = subprocess.call("diff " + filename + " " + ref + " 1>/dev/null", shell=True);
    if ret == 0:
        exit(0);
exit(1);
