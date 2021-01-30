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

    long min, max;
    AliasSeq!(min, max) = r.fold!(std.algorithm.min, std.algorithm.max);

    long k = lround(double(max - min + 1) / r.length);
    import std.stdio;
    auto shift = bsr(k);
    alias b = x => (x - min) >> shift;

    version (Prof) {
        import std.datetime.stopwatch : StopWatch;
        import std.stdio : writeln;
        StopWatch sw;
        sw.start();
    }
    auto buff = new ubyte[](long[].sizeof * r.length + 4 * long.sizeof * r.length);
    auto sectionsRaw = cast(RawSlice[]) buff[0 .. long[].sizeof * r.length];
    buff = buff[long[].sizeof * r.length .. $];
    foreach (i; ref section; sectionsRaw) {
        section.ptr = buff.ptr + i * 4 * long.sizeof;
        section.length = 0;
    }
    auto sections = cast(long[][]) sectionsRaw;
    version (Prof) {
        sw.stop();
        sw.peek.writeln(" ", __LINE__);
        sw.reset();
        sw.start();
    }
    foreach (ref sec; sections)
        sec.length = 0;

    version (Prof) {
        sw.stop();
        sw.peek.writeln(" ", __LINE__);
        sw.reset();
        sw.start();
    }

    foreach (x; r)
        sections[b(x)] ~= x;

    version (Prof) {
        sw.stop();
        sw.peek.writeln(" ", __LINE__);
        sw.reset();
        sw.start();
    }

    auto ret = sections.map!(std.algorithm.sort).join;

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
    	GC.disable;
    	sw.start();
    	data = fastSort(data);
        sw.stop();
        GC.enable;
        GC.collect();
        enforce(data.isSorted);
	}

    writeln(sw.peek);

    sw.reset();

	foreach (i; 0 .. NR) {
    	auto data = iota(args[1].to!size_t).map!(i => uniform(0L, args[1].to!long)).array;
    	sw.start();
    	data = phobosSort(data);
        sw.stop();
        enforce(data.isSorted);
	}

    writeln(sw.peek);
}

enum NR = 1;
