pragma(inline, false)
long[] countingSort(long[] r) {
    import core.bitop : bsr;
    import core.stdc.stdlib : calloc, free;
    import std.algorithm.sorting : sort;
    import std.math : lround;
    import std.meta : AliasSeq;
    import std.typecons : tuple;

    long min, max;
    AliasSeq!(min, max) = minMax(r);

    auto targetNumPerBin = 64;
    long k = targetNumPerBin * lround(double(max - min + 1) / r.length);
    auto shift = bsr(k);
    alias b = (long x) => size_t(x - min) >> shift;
    auto nBins = b(max) + 1;

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

    auto res = new long[](r.length);
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


struct RawSlice {
    size_t length;
    void* ptr;
}

auto minMax(R)(R r) {
    import std.typecons : tuple;

    long min = r[0];
    long max = r[0];
    foreach (el; r[1 .. $]) {
        if (el < min)
            min = el;
        if (el > max)
            max = el;
    }
    return tuple(min, max);
}

pragma(inline, false)
long[] bucketSort(long[] r) {
    static import std.algorithm;
    import std.meta : AliasSeq;
    import std.math : lround, floor;
    import std.array : join;
    import std.algorithm : fold, map;
    import core.bitop : bsr;
    import core.stdc.stdlib : calloc, free;

    import std.stdio : writeln;

    long min, max;
    AliasSeq!(min, max) = minMax(r);

    auto targetNumPerBin = 64;
    long k = targetNumPerBin * lround(double(max - min + 1) / r.length);
    auto shift = bsr(k);
    alias b = x => (x - min) >> shift;
    auto nBins = b(max) + 1;
    //writeln(nBins);

    version (Prof) {
        import std.datetime.stopwatch : StopWatch;
        import std.stdio : writeln;
        StopWatch sw;
        sw.start();
    }
    enum maxSectionSize = 128;
    auto nBytesInHeader = (long[]).sizeof * nBins;
    auto buffLen = nBytesInHeader + maxSectionSize * long.sizeof * nBins;
    version (calloc) {
        auto p = calloc(buffLen, 1);
        if (p is null)
            assert(0, "memory allocation failed");
        scope (exit)
            free(p);
        auto buff = (cast(ubyte*) p)[0 .. buffLen];
    }
    else
        auto buff = new ubyte[](buffLen);
    auto sectionsRaw = cast(RawSlice[]) buff[0 .. nBytesInHeader];
    buff = buff[nBytesInHeader .. $];
    foreach (i, ref section; sectionsRaw) {
        section.ptr = buff.ptr + i * maxSectionSize * long.sizeof;
        //section.length = 0;
    }
    alias insert = (i, x) {
        auto arr = &sectionsRaw[i];
        if (arr.length == maxSectionSize)
            assert(0);
        (cast(long*) arr.ptr)[arr.length++] = x;
    };

    version (Prof) {
        sw.stop();
        sw.peek.writeln(" ", __LINE__);
        sw.reset();
        sw.start();
    }

    foreach (x; r)
        insert(b(x), x);

    version (Prof) {
        sw.stop();
        sw.peek.writeln(" ", __LINE__);
        sw.reset();
        sw.start();
    }

    //writeln(sections);

    auto rp = r.ptr;
    auto sections = cast(long[][]) sectionsRaw;
    foreach (section; sections) {
        rp[0 .. section.length] = std.algorithm.sort(section).release;
        rp += section.length;
    }

    version (Prof) {
        sw.stop();
        sw.peek.writeln(" ", __LINE__);
    }

    return r;
}

pragma(inline, false)
long[] phobosSort(long[] r) {
    import std.algorithm : sort;
    r.sort();
    return r;
}

void main(string[] args) {
    import std.random : uniform;
    import std.datetime.stopwatch : StopWatch;
    import std.algorithm : map, isSorted;
    import std.range : iota;
    import std.array : array;
    import std.conv : to;
    import std.exception : enforce;
    import std.stdio : writeln;

    import core.memory : GC;
    StopWatch sw;

    alias getData = () => iota(args[1].to!size_t).map!(i => uniform(0L, args[1].to!long / 1000)^^5).array;
    /+
    foreach (i; 0 .. NR) {
        auto data = iota(args[1].to!size_t).map!(i => uniform(0L, args[1].to!long)).array;
        auto orig = data.dup;
        GC.disable;
        sw.start();
        data = bucketSort(data);
        sw.stop();
        GC.enable;
        GC.collect();
        enforce(data.isSorted && data == orig.phobosSort);
    }

    writeln(sw.peek);

    sw.reset();
    +/
    foreach (i; 0 .. NR) {
        auto data = getData();
        auto orig = data.dup;
        GC.disable;
        sw.start();
        data = countingSort(data);
        sw.stop();
        GC.enable;
        GC.collect();
        enforce(data.isSorted && data == orig.phobosSort);
    }

    writeln(sw.peek);

    sw.reset();
    foreach (i; 0 .. NR) {
        auto data = getData();
        sw.start();
        data = phobosSort(data);
        sw.stop();
    }

    writeln(sw.peek);

    sw.reset();
    foreach (i; 0 .. NR) {
        auto data = getData();
        sw.start();
        data = cppSort_(data);
        sw.stop();
    }

    writeln(sw.peek);
}

extern (C) long[] cppSort(long[] r);
pragma(inline, false)
long[] cppSort_(long[] r) {
    return cppSort(r);
}

enum NR = 1;
