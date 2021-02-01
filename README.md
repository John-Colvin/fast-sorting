# Counting go brrrrr

```
(ldc-1.25.0-beta1)john@john-ryzen-ubuntu:~/Git/bucket-sorts$ ./experiment.sh Uniform 1000000
prePartitioned: 59 ms, 393 μs, and 5 hnsecs
std.sort:       54 ms, 363 μs, and 5 hnsecs
std::sort:      39 ms, 580 μs, and 6 hnsecs
(ldc-1.25.0-beta1)john@john-ryzen-ubuntu:~/Git/bucket-sorts$ ./experiment.sh Squared 1000000
prePartitioned: 8 ms, 286 μs, and 8 hnsecs
std.sort:       53 ms, 376 μs, and 3 hnsecs
std::sort:      41 ms, 482 μs, and 6 hnsecs
(ldc-1.25.0-beta1)john@john-ryzen-ubuntu:~/Git/bucket-sorts$ ./experiment.sh Forward 1000000
prePartitioned: 9 ms, 586 μs, and 5 hnsecs
std.sort:       3 ms, 471 μs, and 8 hnsecs
std::sort:      9 ms, 749 μs, and 8 hnsecs
(ldc-1.25.0-beta1)john@john-ryzen-ubuntu:~/Git/bucket-sorts$ ./experiment.sh Reverse 1000000
prePartitioned: 8 ms, 315 μs, and 8 hnsecs
std.sort:       3 ms, 707 μs, and 3 hnsecs
std::sort:      8 ms and 150 μs
(ldc-1.25.0-beta1)john@john-ryzen-ubuntu:~/Git/bucket-sorts$ ./experiment.sh Comb 1000000
prePartitioned: 5 ms, 668 μs, and 1 hnsec
std.sort:       14 ms, 961 μs, and 2 hnsecs
std::sort:      29 ms, 816 μs, and 4 hnsecs
(ldc-1.25.0-beta1)john@john-ryzen-ubuntu:~/Git/bucket-sorts$ ./experiment.sh ReverseComb 1000000
prePartitioned: 8 ms, 62 μs, and 2 hnsecs
std.sort:       20 ms, 116 μs, and 1 hnsec
std::sort:      38 ms, 956 μs, and 2 hnsecs
```
