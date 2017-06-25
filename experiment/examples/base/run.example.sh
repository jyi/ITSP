#!/bin/bash

examples=$(ls -1 base-Lab*.sh)

for example in ${examples[@]}; do
    ./$example
    cat result-base
    echo ""
done
