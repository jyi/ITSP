#!/usr/bin/env python
import subprocess
from os import system

if __name__ == "__main__":
    f = open("__tmp.c", "w");
    print >> f, "#include <stddef.h>"
    print >> f, "int main() { return 0; }"
    f.close();
    p = subprocess.Popen(["clang", "-v", "__tmp.c", "-o", "__tmp"], stderr = subprocess.PIPE);
    (out, err) = p.communicate();
    lines = err.strip().split("\n");
    enabled = False;
    print "\"",
    for line in lines:
        line = line.strip();
        tokens = line.split();
        if len(tokens) == 0:
            continue;
        if tokens[0] == "#include":
            enabled = True;
        elif tokens[0] == "End":
            enabled = False;
        elif (line[0] == '/') and enabled:
            print "-I"+line+" ",
    print "\""
    system("rm -rf __tmp*");
