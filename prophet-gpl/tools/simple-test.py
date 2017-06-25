#!/usr/bin/env python
from sys import argv
from os import system
import getopt

if __name__ == "__main__":
    if len(argv) < 4:
        print "Usage: php-tester.py <src_dir> <test_dir> <work_dir> [cases]";
        exit(1);

    opts, args = getopt.getopt(argv[1:], "p:");
    profile_dir = "";
    for o, a in opts:
        if o == "-p":
            profile_dir = a;

    src_dir = args[0];
    test_dir = args[1];
    work_dir = args[2];
    if profile_dir == "":
        cur_dir = src_dir;
    else:
        cur_dir = profile_dir;
    if len(args) > 3:
        ids = args[3:];
        for i in ids:
            if (i != "0"):
                cmd = cur_dir + "/prog " + test_dir + "/"+ i + ".in 1> __out";
            else:
                cmd = cur_dir + "/prog 1> __out";
            ret = system(cmd);
            if (ret == 0):
                cmd = "diff __out " + test_dir + "/" + i + ".exp 1> /dev/null";
                ret = system(cmd);
                if (ret == 0):
                    print i,
            system("rm -rf __out");
        print;
