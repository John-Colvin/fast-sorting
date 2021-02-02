#!/usr/bin/env bash
set -euo pipefail

clang++ -O3 -march=native -c cppsort.cpp -o cppsort.o
/usr/bin/time -v ldc2 -O5 -release -boundscheck=off -mcpu=native -d-version=$1 -flto=full fastsort.d cppsort.o
./fastsort $2
