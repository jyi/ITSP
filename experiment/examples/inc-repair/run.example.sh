#!/bin/bash

examples=$(ls -1 inc-repair-Lab*.sh)

for example in ${examples[@]}; do
    ./$example
    cat result-inc-repair
    echo ""
done
