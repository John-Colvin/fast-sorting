// IGNORE FOR NOW, ABANDONED
//
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

