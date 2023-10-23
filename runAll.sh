#!/usr/bin/env bash
set -euo pipefail

./build.sh

N=20000
experiments=("Uniform" "UniformEqualRange" "UniformFullRange" "Squared" "SmoothPow4" "Forward" "Reverse" "Comb" "ReverseComb" "RandomBinary" "RandomBigBinary" "OrganPipe" "MinAtBack" "MaxAtFront" "FlatSpike" "RampSpike" "Sequences" "ReverseSequences")

for experiment in ${experiments[@]}; do
    echo $experiment
    ./fastsort $experiment $N
    echo
done
