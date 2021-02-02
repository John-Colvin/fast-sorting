alias Elem = int;

Elem[] binnedCountingSort(Elem[] r) {
    pragma(LDC_never_inline);

    import core.bitop : bsr;
    import core.stdc.stdlib : calloc, free;
    import std.algorithm.sorting : sort;
    import std.math : lround;
    import std.meta : AliasSeq;
    import std.typecons : tuple;

    Elem min, max;
    AliasSeq!(min, max) = minMax(r);

    // magic number that seems to work well. Results are mostly not that
    // sensitive to it though
    enum targetNumPerBin = 16;
    // Divisor for the keys to decide which bin they go in, based on targetNumPerBin
    immutable k = targetNumPerBin * lround(double(max - min + 1) / r.length);
    // But actually we go for a power of two and do it as a shift, for speed
    immutable shift = bsr(k);
    // Choose the bin, based on the key
    size_t b(Elem x) {
        pragma(inline, true);
        return size_t(x - min) >> shift;
    }
    immutable nBins = b(max) + 1;

    auto p = calloc(nBins * size_t.sizeof, 1);
    if (p is null)
        assert(0, "memory allocation failed");
    scope (exit)
        free(p);
    auto counts = (cast(size_t*) p)[0 .. nBins];

    // count how many will go in each bin
    foreach (immutable el; r)
        counts[b(el)]++;

    // turn that in to a cumulative count starting at 0
    // the top count is lost from counts but that's implicit from the length of the input
    size_t total = 0;
    foreach (ref count; counts)
        AliasSeq!(count, total) = tuple(total, count + total);

    // put everything in its place based on the counts.
    auto res = new Elem[](r.length);
    foreach (immutable el; r) {
        auto countPtr = counts.ptr + b(el);
        res[*countPtr] = el;
        (*countPtr)++;
    }

    // sort each bin separately.
    // if shift is 0 then each bin is uniform, so no need to sort them
    if (shift != 0) {
        res[0 .. counts[0]].sort();
        foreach (i; 1 .. counts.length)
            res[counts[i - 1] .. counts[i]].sort();
    }

    return res;
}

auto minMax(R)(R r) {
    import std.typecons : tuple;

    Elem min = r[0];
    Elem max = r[0];
    foreach (el; r[1 .. $]) {
        if (el < min)
            min = el;
        if (el > max)
            max = el;
    }
    return tuple(min, max);
}

pragma(inline, false)
Elem[] phobosSort(Elem[] r) {
    import std.algorithm : sort;
    r.sort();
    return r;
}

extern (C) Elem[] cppSortImpl(Elem[] r);

pragma(inline, false)
Elem[] cppSort(Elem[] r) {
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
        alias getData = () => iota(len).map!(i => uniform(Elem(0), len.to!Elem / 100)).array;
    version (Squared)
        alias getData = () => iota(len).map!(i => uniform(Elem(0), len.to!Elem / 100)^^2).array;
    version (SmoothSquared)
        alias getData = () => iota(len).map!(i => uniform(Elem(0), ((len.to!double / 10000)^^2).to!Elem)).array;
    version (Forward)
        alias getData = () => iota(len).map!(i => i.to!Elem).array;
    version (Reverse)
        alias getData = () => iota(len).map!(i => i.to!Elem).retro.array;
    version (Comb)
        alias getData = () => iota(len).map!(i => (i + ((i & 1) ? len / 2 : 0)).to!Elem).array;
    version (ReverseComb)
        alias getData = () => iota(len).map!(i => (i + ((i & 1) ? len / 2 : 0)).to!Elem).retro.array;

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
        GC.disable();
        data = cppSort(data);
        GC.enable();
        sw.stop();
    }

    writeln("std::sort:      ", sw.peek);
}

enum NR = 10;
