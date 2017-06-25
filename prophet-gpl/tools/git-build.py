#!/usr/bin/env python
from os import getcwd, chdir, path
from sys import argv
import subprocess
from print_fixes import print_fixes

def switch_to(out_dir, revision):
    ori_dir = getcwd();
    chdir(out_dir);
    ret = subprocess.call(["git", "checkout", revision, "-f"]);
    if ret != 0:
        print "Failed to swtich to the revision " + revision;
        chdir(ori_dir);
        exit(1);

    ret = subprocess.call(["autoreconf", "-fvi"]);
    if ret != 0:
        print "Failed to create config, check autoconf!";
        chdir(ori_dir);
        exit(1);
    ret = subprocess.call(["./configure"]);
    if ret != 0:
        print "Failed to run configure!";
        chdir(ori_dir);
        exit(1);
    subprocess.call(["make", "clean"]);
    ret = subprocess.call(["make", "-j", "2"]);
    if ret != 0:
        print "Failed to compile!";
        chdir(ori_dir);
        exit(1);
    chdir(ori_dir);

if __name__=="__main__":
    github_addr = "https://github.com/git/git.git"
    if len(argv) < 2:
        print "Usage: git-build.py <directory> [revision]"
        exit(0);

    out_dir = argv[1];
    # fetch from github if the directory does not exist
    if path.exists(argv[1]):
        print "Working with existing directory: " + argv[1];
    else:
        ret = subprocess.call(["git", "clone", github_addr, out_dir]);
        if ret != 0:
            print "Failed to grab from github, check your network connectiona nd make sure you have git."
            exit(1);

    if len(argv) > 2:
        revision = argv[2];
        switch_to(out_dir, revision);
    else:
        print_fixes(out_dir);
