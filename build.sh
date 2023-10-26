#!/usr/bin/env bash
set -euo pipefail

printInfo=-d-debug=PrintInfo
#printInfo=

job="$1"

clang++ -g -O3 -march=native -c cppsort.cpp -o cppsort.o -fpie -I/opt/homebrew/include/
ldc2 -g -mcpu=native $printInfo *.d cppsort.o \
    -L-lstdc++ -march=aarch64 -of fastsort -d-version="$job"

codesign -s - -v -f --entitlements ./debug.plist ./fastsort