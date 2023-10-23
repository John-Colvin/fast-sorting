import std.range.primitives : isInputRange, empty;

alias Elem = long;

Elem[] binnedCountingSort(Elem)(Elem[] r) {
    pragma(inline, false);

    import std.meta : AliasSeq;
    import std.traits : Unsigned;

    Elem min, max;
    size_t nOutOfOrder;
    AliasSeq!(min, max) = stats(r, nOutOfOrder);
    //import std.stdio;
    //writeln(nOutOfOrder);
    if (nOutOfOrder == 0) {
        return r.dup;
    }

    // magic number that seems to work well. Results are mostly not that
    // sensitive to it though
    // 16 seems sensible idk
    enum targetNumPerBin = 10;
    // Divisor for the keys to decide which bin they go in, based on targetNumPerBin
    immutable k = targetNumPerBin * double(Unsigned!Elem(max) - min) / r.length;

    /+ // for future floating point support
    if (k < 0.75) // TODO: should be something with sqrt(2)???
        return r.binnedCountingSortImpl!(Scaling.up)(min, max, k);
    +/
    if (k >= 1.5) // TODO: ditto
        return r.binnedCountingSortImpl!(Scaling.down)(min, max, k);
    return r.binnedCountingSortImpl!(Scaling.none)(min, max, k);
}

enum Scaling {
    up, /// only relevant for floating point
    down,
    none
}

Elem[] binnedCountingSortImpl(Scaling scaling)(Elem[] r, immutable Elem min,
    immutable Elem max, immutable double k)
in (scaling > 0)
body {
    import core.stdc.stdlib : calloc, free;
    import phobossort : sort;
    import std.math : lround, log2;
    import std.meta : AliasSeq;
    import std.traits : Unsigned;
    import std.typecons : tuple;

    // Choose the bin, based on the key
    static if (scaling == Scaling.none) {
        version (PrintInfo) immutable shift = 0;
        size_t b(Elem x) {
            pragma(inline, true);
            return Unsigned!Elem(x) - min;
        }
    }
    else static if (scaling == Scaling.down) {
        immutable shift = lround(log2(k));
        assert(shift > 0);
        size_t b(Elem x) {
            pragma(inline, true);
            return (Unsigned!Elem(x) - min) >> shift;
        }
    }
    /+ // for future floating point support
    else static if (scaling == Scaling.up) {
        immutable shift = lround(log2(1/k));
        assert(shift > 0);
        size_t b(Elem x) {
            pragma(inline, true);
            return (Unsigned!Elem(x) - min) << shift;
        }
    }+/
    else static assert(0);

    immutable nBins = b(max) + 1;

    version (PrintInfo) {
        import std.stdio;
        writeln("length: ", r.length, " scaling: ", scaling, " min: ", min, " max: ", max, " k: ", k,
            " shift: ", shift, " nBins: ", nBins, " nPerBin: ", double(r.length) / nBins);
    }

    auto p = calloc(nBins * size_t.sizeof, 1);
    if (p is null)
        assert(0, "memory allocation failed");
    scope (exit)
        free(p);
    auto counts = (cast(size_t*) p)[0 .. nBins];

    // count how many will go in each bin
    foreach (immutable el; r)
        counts[b(el)]++;

    version (PrintInfo) {{
        auto countStats = minMax(counts);
        writeln("counts min: ", countStats[0], " counts max: ", countStats[1]);
    }}

    auto res = new Elem[](r.length);

    // turn that in to a cumulative count starting at 0
    // the top count is lost from counts but that's implicit from the length of the input
    size_t total = cast(size_t) res.ptr;
    foreach (ref count; counts)
        AliasSeq!(count, total) = tuple(total, (count * Elem.sizeof) + total);
    
    auto buckets = cast(Elem*[]) counts;

    // put everything in its place based on the counts.
    foreach (immutable el; r) {
        *(buckets[b(el)]++) = el;
    }

    // sort each bin separately.
    // if shift is 0 then each bin is uniform, so no need to sort them
    static if (scaling != Scaling.none) {
        res[0 .. buckets[0] - res.ptr].sortIfNecessary2();
        foreach (i; 1 .. buckets.length)
            buckets[i - 1][0 .. buckets[i] - buckets[i-1]].sortIfNecessary2();
    }

    return res;
}

pragma(inline, true)
auto sortIfNecessary(Elem[] r) {
    import std.range : assumeSorted;
    import std.algorithm : sort;
    foreach (i; 1 .. r.length) {
        if (r[i - 1] > r[i]) {
            return r.sort();
        }
    }
    return r.assumeSorted;
}

pragma(inline, true)
auto sortIfNecessary2(Elem[] r) {
    import std.range : assumeSorted;
    import std.algorithm : sort, swap, min;

    r[0 .. min(3, r.length)].sort();
    foreach (i; 3 .. r.length) {
        if (r[i - 2] > r[i]) {
            r.sort();
            return;
        }
        if (r[i - 1] > r[i]) {
            swap(r[i - 1], r[i]);
        }
    }
}

auto minMaxPresort(R)(R r)
if (isInputRange!R)
in (!r.empty)
do {
    import std.typecons : tuple;
    import std.algorithm : swap;

    auto min = r[0];
    auto max = r[0];
    foreach (i; 1 .. r.length) {
        const el = r[i];
        if (el < min)
            min = el;
        if (el > max)
            max = el;
        if (r[i - 1] > el) {
            r[i] = r[i - 1];
            r[i - 1] = el;
        }
    }
    return tuple(min, max);
}

auto minMax(R)(ref R r)
if (isInputRange!R)
in (!r.empty)
do {
    import std.typecons : tuple;

    auto min = r[0];
    auto max = r[0];
    foreach (el; r[1 .. $]) {
        if (el < min)
            min = el;
        if (el > max)
            max = el;
    }
    return tuple(min, max);
}

auto stats(R)(ref R r, out size_t nOutOfOrder)
if (isInputRange!R)
in (!r.empty)
do {
    import std.typecons : tuple;

    auto min = r[0];
    auto max = r[0];
    nOutOfOrder = 0;
    foreach (i; 1 .. r.length) {
        const el = r[i];
        if (el < min)
            min = el;
        if (el > max)
            max = el;
        nOutOfOrder += (r[i - 1] > el);
    }
    return tuple(min, max);
}

/+ WIP
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
+/

// Elem[] sortish(Elem[] r) {
//     foreach (i; 0 .. r) {
        
//     }
// }

pragma(inline, false)
Elem[] phobosSort(Elem[] r) {
    import phobossort: sort;
    r.sort();
    return r;
}

extern (C) Elem[] cppSortImpl(Elem[] r);

pragma(inline, false)
Elem[] cppSort(Elem[] r) {
    return cppSortImpl(r);
}

extern (C) Elem[] kxSortImpl(Elem[] r);

pragma(inline, false)
Elem[] kxSort(Elem[] r) {
    return kxSortImpl(r);
}

extern (C) Elem[] boostSortImpl(Elem[] r);

pragma(inline, false)
Elem[] boostSort(Elem[] r) {
    return boostSortImpl(r);
}

pragma(inline, false)
void main(string[] args) {
    import std.random : uniform, choice;
    import std.datetime.stopwatch : StopWatch;
    import std.algorithm : map, isSorted;
    import std.range : iota, retro, chain, cycle, drop, dropOne, takeExactly, repeat;
    import std.array : array;
    import std.conv : to;
    import std.exception : enforce;
    import std.stdio : writeln;

    import core.memory : GC;
    StopWatch sw;

    immutable experiment = args[1];
    immutable len = args[2].to!size_t;

    Elem[] delegate() getData;
    switch(experiment) {
        case "Uniform":
            getData = () => iota(len).map!(i => uniform(Elem(0), len.to!Elem / 100)).array;
            break;
        case "UniformEqualRange":
            getData = () => iota(len).map!(i => uniform(Elem(0), len.to!Elem)).array;
            break;
        case "UniformFullRange":
            getData = () => iota(len).map!(i => uniform(Elem.min, Elem.max)).array;
            break;
        case "Squared":
            getData = () => iota(len).map!(i => uniform(Elem(0), len.to!Elem / 100)^^2).array;
            break;
        case "SmoothPow4":
            getData = () => iota(len).map!(i => uniform(Elem(0), ((len.to!double / 10000)^^4).to!Elem)).array;
            break;
        case "Forward":
            getData = () => iota(len).map!(i => i.to!Elem).array;
            break;
        case "Reverse":
            getData = () => iota(len).map!(i => i.to!Elem).retro.array;
            break;
        case "Comb":
            getData = () => iota(len).map!(i => (i + ((i & 1) ? len / 2 : 0)).to!Elem).array;
            break;
        case "ReverseComb":
            getData = () => iota(len).map!(i => (i + ((i & 1) ? len / 2 : 0)).to!Elem).retro.array;
            break;
        case "RandomBinary":
            getData = () => iota(len).map!(i => choice([Elem(0), Elem(1)])).array;
            break;
        case "RandomBigBinary":
            getData = () => iota(len).map!(i => choice([Elem.max / 2, Elem.max])).array;
            break;
        case "OrganPipe":
            getData = () => iota((len / 2).to!Elem).chain((len & 1) ? [(1 + len / 2).to!Elem] : [], iota((len / 2).to!Elem).retro).array;
            break;
        case "MinAtBack":
            getData = () => iota(len).map!(i => i.to!Elem).cycle.dropOne.takeExactly(len).array;
            break;
        case "MaxAtFront":
            getData = () => iota(len).map!(i => i.to!Elem).cycle.drop(len - 1).takeExactly(len).array;
            break;
        case "FlatSpike":
            getData = () => chain([Elem(10000)], repeat(0, len - 1)).array;
            break;
        case "RampSpike":
            getData = () => chain([(len * 10).to!Elem], iota((len - 1).to!Elem)).array;
            break;
        default:
            throw new Exception("did not recognise experiment \"" ~ experiment ~ "\"");
    }

    foreach (i; 0 .. NR) {
        auto data = getData();
        auto orig = data.dup;
        //GC.disable;
        sw.start();
        data = binnedCountingSort(data);
        sw.stop();
        //GC.enable;
        //GC.collect();
        import std.conv : text;
        enforce(data.isSorted, data.text);
        enforce(data == orig.phobosSort);
    }

    writeln("binned sort:                          ", sw.peek);

    sw.reset();
    foreach (i; 0 .. NR) {
        auto data = getData();
        sw.start();
        data = phobosSort(data);
        sw.stop();
    }

    writeln("std.algorithm.sort:                   ", sw.peek);

    sw.reset();
    foreach (i; 0 .. NR) {
        auto data = getData();
        auto orig = data.dup;
        sw.start();
        data = cppSort(data);
        sw.stop();
        enforce(data.isSorted && data == orig.phobosSort);
    }

    writeln("std::sort:                            ", sw.peek);

    sw.reset();
    foreach (i; 0 .. NR) {
        auto data = getData();
        auto orig = data.dup;
        sw.start();
        data = kxSort(data);
        sw.stop();
        enforce(data.isSorted && data == orig.phobosSort);
    }

    writeln("kx::radix_sort:                       ", sw.peek);

    sw.reset();
    foreach (i; 0 .. NR) {
        auto data = getData();
        auto orig = data.dup;
        sw.start();
        data = boostSort(data);
        sw.stop();
        enforce(data.isSorted && data == orig.phobosSort);
    }

    writeln("boost::sort::spreadsort::integer_sort ", sw.peek);
}

enum NR = 10;
