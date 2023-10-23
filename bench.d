module bench;

template runBench(Output, alias getData, alias checker, int NR = 10) {
    alias Input = typeof(getData());
    alias FT = Output delegate(Input);
    pragma(inline, false)
    void runBench(FT[string] contenders) {
        import std.array : array;
        import std.datetime.stopwatch : StopWatch;
        import std.stdio : writeln;
        import std.range : repeat;

        foreach (name, run; contenders) {
            StopWatch sw;
            foreach (i; 0 .. NR) {
                auto data = getData();
                auto orig = data.array;
                //GC.disable;
                sw.start();
                auto res = run(data);
                sw.stop();
                //GC.enable;
                //GC.collect();
                checker(orig, res);
            }
            writeln(name, ' '.repeat(50 - name.length), sw.peek);
        }
    }
}
