#!/usr/bin/env python
from sys import argv, stderr
from os import path
import subprocess

#FIXME: this is very hacky, should properly handle the quote case
def fix_argv(s):
    if (s[0:2] == "-D") and (s.find('="') != -1):
        idx2 = s.find('="');
        idx3 = s.find('"', idx2 + 2);
        return s[0:idx2] + '=\'"' + s[idx2 + 2: idx3] + '"\'' + s[idx3 + 1:];
    elif (s.find('(') != -1) or (s.find(')') != -1):
        return '"' + s + '"';
    elif (s == "$$fb_icon$$.o"):
        return '"\\$\\$fb_icon\\$\\$.o"';
    else:
        return s;

for i in range(1, len(argv)):
    argv[i] = fix_argv(argv[i]);

fulldir = path.abspath(path.dirname(argv[0]));
runtime_library_path = fulldir + "/../src/.libs"

if (len(argv) > 1 and argv[1].find("-print-prog-name") != 0):
    cmd = "/usr/bin/ld" + " -rpath=" + runtime_library_path + " -L " + runtime_library_path + " " + " ".join(argv[1:]) + " -lprofile_runtime -ltest_runtime";
else:
    cmd = "/usr/bin/ld" + " " + " ".join(argv[1:]);

#print >>stderr, cmd;
ret = subprocess.call(cmd, shell=True);
exit(ret);
