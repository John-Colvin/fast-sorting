module bench;

template runBench(Output, alias getData, alias checker) {
    alias Input = typeof(getData());
    alias DT = Output delegate(Input);
    alias FT = Output function(Input);

    void runBenchImpl(size_t NR, FT[string] contenders) {
        import std.algorithm : map;
        import std.array : byPair, assocArray;
        import std.functional : toDelegate;
        import std.typecons : tuple;
        runBench(NR, contenders.byPair.map!(p => tuple(p.key, p.value.toDelegate)).assocArray);
    }

    pragma(inline, false)
    void runBenchImpl(size_t NR, DT[string] contenders) {
        pragma(LDC_never_inline);
        import core.memory : GC;
        import std.algorithm : sort;
        import std.array : array, byPair;
        import std.datetime.stopwatch : StopWatch;
        import std.stdio : writeln, writefln, write, stdout;
        import std.range : repeat;

        foreach (name, run; contenders.byPair.array.sort!((a, b) => a.key < b.key)) {
            StopWatch sw;
            write(name, ' '.repeat(50 - name.length));
            stdout.flush;
            foreach (i; 0 .. NR) {
                auto data = getData();
                //import std.stdio;
                //writeln(data);
                auto orig = data.array;
                GC.disable;
                sw.start();
                auto res = run(data);
                sw.stop();
                GC.enable;
                GC.collect();
                checker(orig, res);
            }
            writefln("%20s", sw.peek.total!"usecs");
        }
    }
    alias runBench = runBenchImpl;
}
