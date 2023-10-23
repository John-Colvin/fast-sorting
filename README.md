# Counting go brrrrr

DANGER!! KNOWN BUGS!!!

`fastsort.d` has the real work in it

`build.sh` builds it

`runAll.sh` runs all the benchmark tests

```
Uniform
binned sort:        37 ms, 19 μs, and 8 hnsecs
std.algorithm.sort: 529 ms, 539 μs, and 6 hnsecs
std::sort:          413 ms, 342 μs, and 9 hnsecs
UniformEqualRange
binned sort:        114 ms, 42 μs, and 6 hnsecs
std.algorithm.sort: 588 ms, 992 μs, and 1 hnsec
std::sort:          538 ms and 766 μs
UniformFullRange
binned sort:        116 ms, 471 μs, and 4 hnsecs
std.algorithm.sort: 593 ms and 879 μs
std::sort:          536 ms, 964 μs, and 4 hnsecs
Squared
binned sort:        61 ms, 767 μs, and 8 hnsecs
std.algorithm.sort: 517 ms, 125 μs, and 3 hnsecs
std::sort:          410 ms, 528 μs, and 8 hnsecs
SmoothPow4
binned sort:        117 ms, 480 μs, and 8 hnsecs
std.algorithm.sort: 600 ms, 527 μs, and 3 hnsecs
std::sort:          529 ms, 210 μs, and 7 hnsecs
Forward
binned sort:        61 ms and 351 μs
std.algorithm.sort: 48 ms and 829 μs
std::sort:          76 ms, 664 μs, and 3 hnsecs
Reverse
binned sort:        82 ms, 582 μs, and 1 hnsec
std.algorithm.sort: 50 ms, 140 μs, and 1 hnsec
std::sort:          89 ms, 934 μs, and 3 hnsecs
Comb
binned sort:        50 ms, 327 μs, and 3 hnsecs
std.algorithm.sort: 163 ms and 110 μs
std::sort:          252 ms, 750 μs, and 4 hnsecs
ReverseComb
binned sort:        76 ms, 392 μs, and 4 hnsecs
std.algorithm.sort: 223 ms, 785 μs, and 6 hnsecs
std::sort:          162 ms, 197 μs, and 9 hnsecs
RandomBinary
binned sort:        45 ms, 262 μs, and 8 hnsecs
std.algorithm.sort: 128 ms and 34 μs
std::sort:          120 ms, 296 μs, and 9 hnsecs
OrganPipe
binned sort:        68 ms, 791 μs, and 3 hnsecs
std.algorithm.sort: 277 ms, 856 μs, and 2 hnsecs
std::sort:          492 ms, 860 μs, and 6 hnsecs
MinAtBack
binned sort:        65 ms, 145 μs, and 7 hnsecs
std.algorithm.sort: 140 ms, 544 μs, and 5 hnsecs
std::sort:          453 ms, 1 μs, and 2 hnsecs
MaxAtFront
binned sort:        58 ms and 95 μs
std.algorithm.sort: 65 ms, 210 μs, and 5 hnsecs
std::sort:          54 ms, 957 μs, and 4 hnsecs
FlatSpike
binned sort:        43 ms, 42 μs, and 1 hnsec
std.algorithm.sort: 80 ms, 709 μs, and 6 hnsecs
std::sort:          79 ms, 925 μs, and 5 hnsecs
RampSpike
binned sort:        67 ms, 281 μs, and 8 hnsecs
std.algorithm.sort: 65 ms, 368 μs, and 5 hnsecs
std::sort:          54 ms, 660 μs, and 7 hnsecs
```
