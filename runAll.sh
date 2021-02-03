#!/usr/bin/env bash
set -euo pipefail

./build.sh

N=1000000
experiments=("Uniform" "UniformEqualRange" "UniformFullRange" "Squared" "SmoothPow4" "Forward" "Reverse" "Comb" "ReverseComb" "RandomBinary" "OrganPipe" "MinAtBack" "MaxAtFront" "FlatSpike" "RampSpike")

for experiment in ${experiments[@]}; do
    echo $experiment
    ./fastsort $experiment $N
done

