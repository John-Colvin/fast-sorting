// void main(string[] args) {
//     import std.conv : to;
//     import std.exception : enforce;
//     import std.algorithm : equal, sort;
//     import exampledata : dataGenerator;
//     import bench : runBench;
//     import othersorts;
//     import fastsort : binnedCountingSort;

//     immutable pattern = args[1];
//     immutable len = args[2].to!size_t;

//     alias Elem = long;
//     enum NR = 10;

//     auto getData = dataGenerator!Elem(pattern, len);

//     runBench!(Elem[], getData, (i, o) => enforce(i.sort.equal(o)), NR)(
//         [
//             "binned sort" : &binnedCountingSort!Elem,
//             "std.algorithm.sort" : &phobosSort!Elem,
//             "std::sort" : &cppSort!Elem,
//             "kx::radix_sort" : &kxSort!Elem,
//             "boost::sort::spreadsort::integer_sort" : &boostSort!Elem
//         ]
//     );
// }

void main(string[] args) {
    import std.algorithm : equal, sort, SwapStrategy;
    import phobossort : makeIndex;
    import std.array : array;
    import std.conv : to;
    import std.exception : enforce;
    import std.range : indexed;
    import exampledata : dataGenerator;
    import bench : runBench;
    import fastmakeindex : makeIndexLessIntegersOnly;

    immutable pattern = args[1];
    immutable len = args[2].to!size_t;

    alias Elem = long;
    enum NR = 500;

    auto getData = dataGenerator!Elem(pattern, len);

    auto index = new size_t[](len);

    runBench!(size_t[], getData, (orig, res) => enforce(orig.indexed(res).equal(orig.array.sort), orig.to!string), NR)(
        [
            "new" : (Elem[] i) {
                makeIndexLessIntegersOnly!(SwapStrategy.unstable)(i, index);
                return index;
            },
            "old" : (Elem[] i) {
                makeIndex!("a < b", SwapStrategy.unstable)(i, index);
                return index;
            }
        ]
    );
}
