pragma(inline, false)
int[] binnedCountingSort(int[] r) {
    import core.bitop : bsr;
    import core.stdc.stdlib : calloc, free;
    import std.algorithm.sorting : sort;
    import std.math : lround;
    import std.meta : AliasSeq;
    import std.typecons : tuple;

    int min, max;
    AliasSeq!(min, max) = minMax(r);

    enum targetNumPerBin = 16;
    immutable k = targetNumPerBin * lround(double(max - min + 1) / r.length);
    immutable shift = bsr(k);
    alias b = (int x) => size_t(x - min) >> shift;
    immutable nBins = b(max) + 1;

    auto p = calloc(nBins * size_t.sizeof, 1);
    if (p is null)
        assert(0, "memory allocation failed");
    scope (exit)
        free(p);
    auto counts = (cast(size_t*) p)[0 .. nBins];

    foreach (el; r) {
        counts[b(el)]++;
    }

    size_t total = 0;
    foreach (ref count; counts)
        AliasSeq!(count, total) = tuple(total, count + total);

    auto res = new int[](r.length);
    foreach (el; r) {
        res[counts[b(el)]] = el;
        counts[b(el)]++;
    }

    if (shift != 0) {
        res[0 .. counts[0]].sort();
        foreach (i; 1 .. counts.length)
            res[counts[i - 1] .. counts[i]].sort();
    }

    return res;
}

auto minMax(R)(R r) {
    import std.typecons : tuple;

    int min = r[0];
    int max = r[0];
    foreach (el; r[1 .. $]) {
        if (el < min)
            min = el;
        if (el > max)
            max = el;
    }
    return tuple(min, max);
}

pragma(inline, false)
int[] phobosSort(int[] r) {
    import std.algorithm : sort;
    r.sort();
    return r;
}

extern (C) int[] cppSortImpl(int[] r);

pragma(inline, false)
int[] cppSort(int[] r) {
    return cppSortImpl(r);
}

void main(string[] args) {
    import std.random : uniform;
    import std.datetime.stopwatch : StopWatch;
    import std.algorithm : map, isSorted;
    import std.range : iota, retro;
    import std.array : array;
    import std.conv : to;
    import std.exception : enforce;
    import std.stdio : writeln;

    import core.memory : GC;
    StopWatch sw;

    immutable len = args[1].to!size_t;

    version (Uniform)
        alias getData = () => iota(len).map!(i => uniform(int(0), len.to!int / 100)).array;
    version (Squared)
        alias getData = () => iota(len).map!(i => uniform(int(0), len.to!int / 100)^^2).array;
    version (Forward)
        alias getData = () => iota(len).map!(i => i.to!int).array;
    version (Reverse)
        alias getData = () => iota(len).map!(i => i.to!int).retro.array;
    version (Comb)
        alias getData = () => iota(len).map!(i => (i + ((i & 1) ? len / 2 : 0)).to!int).array;
    version (ReverseComb)
        alias getData = () => iota(len).map!(i => (i + ((i & 1) ? len / 2 : 0)).to!int).retro.array;

    foreach (i; 0 .. NR) {
        auto data = getData();
        auto orig = data.dup;
        //GC.disable;
        sw.start();
        data = binnedCountingSort(data);
        sw.stop();
        //GC.enable;
        //GC.collect();
        enforce(data.isSorted && data == orig.phobosSort);
    }

    writeln("prePartitioned: ", sw.peek);

    sw.reset();
    foreach (i; 0 .. NR) {
        auto data = getData();
        sw.start();
        data = phobosSort(data);
        sw.stop();
    }

    writeln("std.sort:       ", sw.peek);

    sw.reset();
    foreach (i; 0 .. NR) {
        auto data = getData();
        sw.start();
        data = cppSort(data);
        sw.stop();
    }

    writeln("std::sort:      ", sw.peek);
}

enum NR = 1;
