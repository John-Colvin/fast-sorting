#!/usr/bin/env bash
set -euo pipefail

./build.sh "$1"

N=10000
experiments=("Uniform" "UniformEqualRange" "UniformFullRange" "Squared" "SmoothPow4" "Forward" \
    "Reverse" "Comb" "ReverseComb" "RandomBinary" "RandomBigBinary" "OrganPipe" "MinAtBack" "MaxAtFront" \
    "FlatSpike" "RampSpike" "Sequences" "ReverseSequences" "ShortSequences" "ShortReverseSequences" \
    "PdfSpikes" "PdfSpikeClusters")

for experiment in ${experiments[@]}; do
    echo $experiment
    ./fastsort $experiment $N 1
    echo
done
