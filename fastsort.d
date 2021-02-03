import std.range.primitives : isInputRange, empty;

alias Elem = int;

Elem[] binnedCountingSort(Elem[] r) {
    pragma(LDC_never_inline);

    import std.meta : AliasSeq;
    import std.traits : Unsigned;

    Elem min, max;
    AliasSeq!(min, max) = minMax(r);

    // magic number that seems to work well. Results are mostly not that
    // sensitive to it though
    enum targetNumPerBin = 16;
    // Divisor for the keys to decide which bin they go in, based on targetNumPerBin
    immutable k = targetNumPerBin * double(Unsigned!Elem(max) - min) / r.length;

    if (k < 0.75) // TODO: should be something with sqrt(2)???
        return r.binnedCountingSortImpl!(Scaling.up)(min, max, k);
    if (k >= 1.5) // TODO: ditto
        return r.binnedCountingSortImpl!(Scaling.down)(min, max, k);
    return r.binnedCountingSortImpl!(Scaling.none)(min, max, k);

}

enum Scaling {
    up,
    down,
    none
}

Elem[] binnedCountingSortImpl(Scaling scaling)(Elem[] r, immutable Elem min, immutable Elem max, immutable double k)
in (scaling > 0)
body {
    import core.stdc.stdlib : calloc, free;
    import std.algorithm.sorting : sort;
    import std.math : lround, log2;
    import std.meta : AliasSeq;
    import std.traits : Unsigned;
    import std.typecons : tuple;

    // Choose the bin, based on the key
    static if (scaling == Scaling.none) {
        size_t b(Elem x) {
            pragma(inline, true);
            return Unsigned!Elem(x) - min;
        }
    }
    else static if (scaling == Scaling.down) {
        immutable shift = lround(log2(k));
        size_t b(Elem x) {
            pragma(inline, true);
            return (Unsigned!Elem(x) - min) >> shift;
        }
    }
    else static if (scaling == Scaling.up) {
        immutable shift = lround(log2(1/k));
        size_t b(Elem x) {
            pragma(inline, true);
            return (Unsigned!Elem(x) - min) << shift;
        }
    }
    else static assert(0);

    immutable nBins = b(max) + 1;
    //import std.stdio;
    //writeln("length: ", r.length, " scaling ", scaling, " min: ", min, " max: ", max, " k: ", k, " nBins: ", nBins);

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
    static if (scaling == Scaling.none) {
        res[0 .. counts[0]].sort();
        foreach (i; 1 .. counts.length)
            res[counts[i - 1] .. counts[i]].sort();
    }

    return res;
}

auto minMax(R)(R r)
if (isInputRange!R)
in (!r.empty)
do {
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

auto approximateMedian(R)(R r)
if (isInputRange!R)
in (!r.empty)
do {
    // choose a grid of e.g. 5 points:
    //
    // min,
    // min + (max - min) / 4,
    // min + (max - min) / 2,
    // min + 3 * (max - min) / 4,
    // max
    //
    // where min and max are the running min and max so far
    //
    // count how many elements are within each grid region as you walk
    // range.
    //
    // if you hit a new min or max, create a new grid and interpolate the
    // old counts on to it.
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
    import std.range : iota, retro, chain;
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
    version (RandomBinary)
        alias getData = () => iota(len).map!(i => uniform(Elem(0), Elem(2))).array;
    version (OrganPipe)
        alias getData = () => iota((len / 2).to!Elem).chain((len & 1) ? [(1 + len / 2).to!Elem] : [], iota((len / 2).to!Elem).retro).array;

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
