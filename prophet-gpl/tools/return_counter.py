#!/usr/bin/env python
f = open("repair.log", "r");
lines = f.readlines();
cnt = 0;
for line in lines:
    tokens = line.strip().split();
    if (len(tokens) > 3):
        if (tokens[0] == "Total") and (tokens[1] == "return"):
            cnt += int(tokens[3]);
        if (tokens[0] == "Total") and (tokens[2] == "different") and (tokens[3] == "repair"):
            cnt += int(tokens[1]);
print "Total size: " + str(cnt);
