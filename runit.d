void main(string[] args) {
    import std.algorithm : equal, sort, SwapStrategy;
    import std.array : array;
    import std.conv : to;
    import std.exception : enforce;
    import std.range : indexed;
    import exampledata : dataGenerator;
    import bench : runBench;

    immutable pattern = args[1];
    immutable len = args[2].to!size_t;
    immutable NR = args[3].to!size_t;

    alias Elem = long;

    auto getData = dataGenerator!Elem(pattern, len);

    version (BenchSort) {
        import othersorts;
        import phobossort : phobosSort = sort;
        import fastsort : sortLessIntegersOnly;

        runBench!(Elem[],
            getData,
            (i, o) => enforce(i.sort.equal(o), "\n" ~ i.sort.to!string ~ " !=\n" ~ o.to!string))
            (NR,
            [
                " new stable" : (Elem[] r) => r.sortLessIntegersOnly!(SwapStrategy.stable, Elem[]).release,
                " old stable" : (Elem[] r) => r.dup.phobosSort!("a < b", SwapStrategy.stable, Elem[]).release,
                " new unstable" : (Elem[] r) => r.sortLessIntegersOnly!(SwapStrategy.unstable, Elem[]).release,
                " old unstable" : (Elem[] r) => r.dup.phobosSort!("a < b", SwapStrategy.unstable, Elem[]).release,
                "std::sort" : (Elem[] r) => r.dup.cppSort!Elem,
                "kx::radix_sort" : (Elem[] r) => r.dup.kxSort!Elem,
                "boost::sort::spreadsort::integer_sort" : (Elem[] r) => r.dup.boostSort!Elem,
            ]
        );
    } else version (BenchMakeIndex) {
        import fastmakeindex : makeIndexLessIntegersOnly;
        import phobossort : makeIndex;

        auto index = new size_t[](len);

        runBench!(size_t[],
            getData,
            (orig, res) => enforce(orig.indexed(res).equal(orig.array.sort), "\n" ~ orig.array.sort.to!string ~ " !=\n" ~ orig.indexed(res).to!string))
            (NR,
            [
                "new stable" : (Elem[] i) {
                    makeIndexLessIntegersOnly!(SwapStrategy.stable)(i, index);
                    return index;
                },
                "old stable" : (Elem[] i) {
                    makeIndex!("a < b", SwapStrategy.stable)(i, index);
                    return index;
                },
                "new unstable" : (Elem[] i) {
                    makeIndexLessIntegersOnly!(SwapStrategy.unstable)(i, index);
                    return index;
                },
                "old unstable" : (Elem[] i) {
                    makeIndex!("a < b", SwapStrategy.unstable)(i, index);
                    return index;
                }
            ]
        );
    } else static assert(0);
}
