struct RawSlice {
    size_t length;
    void* ptr;
}

pragma(inline, false)
long[] fastSort(long[] r) {
    static import std.algorithm;
    import std.meta : AliasSeq;
    import std.math : lround, floor;
    import std.array : join;
    import std.algorithm : fold, map;
    import core.bitop : bsr;
    import core.stdc.stdlib : calloc, free;

    import std.stdio : writeln;

    long min = r[0];
    long max = r[0];
    foreach (el; r[1 .. $]) {
        if (el < min)
            min = el;
        if (el > max)
            max = el;
    }

    //AliasSeq!(min, max) = r.fold!(std.algorithm.min, std.algorithm.max);

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
    auto sections = cast(long[][]) sectionsRaw;
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
    foreach (section; sections) {
        rp[0 .. section.length] = std.algorithm.sort(section).release;
        rp += section.length;
    }
    auto ret = r;
    /+
    long[] ret;
    if (k == 1)
        ret = sections.join;
    else
        ret = sections.map!(std.algorithm.sort).join;
        +/

    version (Prof) {
        sw.stop();
        sw.peek.writeln(" ", __LINE__);
    }

    return ret;
}

pragma(inline, false)
long[] phobosSort(long[] r) {
    import std.algorithm : sort;
    r = r.dup;
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

	foreach (i; 0 .. NR) {
    	auto data = iota(args[1].to!size_t).map!(i => uniform(0L, args[1].to!long)).array;
    	auto orig = data.dup;
    	GC.disable;
    	sw.start();
    	data = fastSort(data);
        sw.stop();
        GC.enable;
        GC.collect();
        enforce(data.isSorted && data == orig.phobosSort);
	}

    writeln(sw.peek);

    sw.reset();

	foreach (i; 0 .. NR) {
    	auto data = iota(args[1].to!size_t).map!(i => uniform(0L, args[1].to!long)).array;
    	sw.start();
    	data = phobosSort(data);
        sw.stop();
	}

    writeln(sw.peek);
}

enum NR = 1;
