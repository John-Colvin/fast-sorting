#!/usr/bin/env bash
set -euo pipefail

#printInfo=-d-debug=PrintInfo
printInfo=

clang++ -g -O3 -march=native -c cppsort.cpp -o cppsort.o -fpie -I/opt/homebrew/include/
ldc2 -g -O5 -release -boundscheck=off -mcpu=native $printInfo *.d cppsort.o \
    -L-lstdc++ -march=aarch64 -of fastsort

codesign -s - -v -f --entitlements ./debug.plist ./fastsort