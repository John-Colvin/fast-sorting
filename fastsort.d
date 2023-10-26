module fastsort;

import std.range;
import std.traits;
import std.algorithm.mutation : SwapStrategy;

/+
problems:
 *   low-occupancy areas
 *   unpredictable jumping around

if you could get the list to be more sorted at a macro level,
it would be much more predictable. One trick is to sort chunks
based on their sums, which will take advantage of any larger
scale structure & give a situation where the jumping around
is greatly reduced. However, if the data is truly jumbled up
this won't help much at all, e.g. a uniform choice of [0,10000]
will still be almost as totally free from structure after this

if you could know the number of unique values, or really the
degree of variety in the pdf, then you could maybe know how
to optimally bin?
+/

SortedRange!(Range, "a < b")
sortLessIntegersOnly(SwapStrategy ss = SwapStrategy.unstable, Range)
(Range r)
if (isRandomAccessRange!Range && hasLength!Range &&
    !isInfinite!Range && isIntegral!(ElementType!Range))
{
    import std.meta : AliasSeq;
    import std.traits : Unsigned;
    import std.range : assumeSorted;
    import std.array : uninitializedArray;

    alias Elem = ElementType!Range;

    if (r.empty) {
        return r.assumeSorted!"a < b";
    }

    Unqual!Elem minVal = r[0], maxVal = r[0];
    bool inOrder = true;
    bool inReverseOrder = true;
    foreach (i; 1 .. r.length)
    {
        const el = r[i];
        if (el < minVal)
            minVal = el;
        if (el > maxVal)
            maxVal = el;
        inOrder = inOrder & (r[i - 1] <= el);
        inReverseOrder = inReverseOrder & (r[i - 1] >= el);
    }
    if (inOrder)
    {
        return r.dup.assumeSorted!"a < b";
    }
    if (inReverseOrder)
    {
        auto res = uninitializedArray!(Elem[])(r.length);
        foreach (i, e; r) {
            res[$ - i - 1] = e;
        }
        return res.assumeSorted!"a < b";
    }

    // magic number that seems to work well. Results are mostly not that
    // sensitive to it though
    // 16 seems sensible idk
    enum targetNumPerBin = 2;
    // Divisor for the keys to decide which bin they go in, based on targetNumPerBin
    immutable k = targetNumPerBin * double(cast(Unsigned!Elem) (maxVal - minVal)) / r.length;

    pragma(inline, true)
    auto withIndex(T)() {
        pragma(inline, true)
        auto withScaling(Scaling scaling)() {
            return sortLessIntegersOnlyImpl!(scaling, ss, Range, T)(r, minVal, maxVal, k)
                .assumeSorted!"a < b";
        }
        if (k >= 1.5) {
            return withScaling!(Scaling.down);
        }
        return withScaling!(Scaling.none);
    }
    if (r.length <= size_t(1) + ubyte.max) {
        return withIndex!ubyte;
    }
    if (r.length <= size_t(1) + ushort.max) {
        return withIndex!ushort;
    }
    if (r.length <= size_t(1) + uint.max) {
       return withIndex!uint;
    }
    static assert(size_t.max <= ulong.max, "wtf platform are you on?!?!");
    return withIndex!ulong;
}

private enum Scaling {
    down,
    none
}

pragma(inline, true)
private auto sortLessIntegersOnlyImpl
    (Scaling scaling, SwapStrategy ss, Range, IndexElem)
    (scope Range r, immutable ElementType!Range minVal,
    immutable ElementType!Range maxVal, immutable double k)
in (k > 0)
body {
    import core.stdc.stdlib : calloc, free;
    import std.array : uninitializedArray;
    import std.math : lround, log2;
    import std.traits : Unsigned;

    alias Elem = ElementType!Range;

    // Choose the bin, based on the key
    static if (scaling == Scaling.none)
    {
        debug(PrintInfo) const shift = 0;

        pragma(inline, true)
        IndexElem b(Elem x)
        {
            // note on the subtraction and cast: yes it will overflow for large x
            // and small minVal, but the cast will give correct result
            return cast(IndexElem) (x - minVal);
        }
    }
    else static if (scaling == Scaling.down)
    {
        const shift = lround(log2(k));

        assert(shift > 0);
        pragma(inline, true)
        IndexElem b(Elem x)
        {
            return (cast(IndexElem) (x - minVal)) >> shift;
        }
    }
    else static assert(0);

    const nBins = (cast(size_t) b(maxVal)) + 1;

    debug(PrintInfo)
    {{
        import std.stdio : stderr;
        stderr.writeln("length: ", r.length, " scaling: ", scaling, " min: ", minVal, " max: ", maxVal, " k: ", k,
            " shift: ", shift, " nBins: ", nBins, " nPerBin: ", double(r.length) / nBins, " indexT ", IndexElem.stringof);
    }}

    //pragma(inline, true)
    static IndexElem[] tmpMem(size_t nBins) @trusted
    {
        version (StaticBuffer)
        {
            static IndexElem[] buff;
            if (buff.length >= nBins) {
                buff[0 .. nBins] = 0;
                return buff[0 .. nBins];
            }
            buff.length = nBins;
            buff[] = 0;
            return buff;
        }
        else
        {
            auto p = calloc(nBins, IndexElem.sizeof);
            //import std.stdio;
            //stderr.writeln("allocated: ", nBins * IndexElem.sizeof);
            if (p is null)
            {
                assert(0, "memory allocation failed");
            }
            return (cast(IndexElem*) p)[0 .. nBins];
        }
    }
    scope counts = tmpMem(nBins);
    version (StaticBuffer) {} else
    {
        scope (exit)
            (() @trusted { free(counts.ptr); })();
    }

    // count how many will go in each bin
    foreach (el; r.save)
    {
        counts[b(el)]++;
    }

    debug(PrintInfo)
    {
        import std.algorithm : fold, min, max;
        import std.stdio : stderr;
        stderr.writeln("counts min: ", fold!min(counts), " counts max: ", fold!max(counts));
    }

    // turn that in to a cumulative count starting at 0
    // the top count is lost from counts but that's implicit from the length of the input
    IndexElem total = 0;
    foreach (ref count; counts)
    {
        auto oldCount = count;
        count = total;
        total += oldCount;
    }

    auto res = uninitializedArray!(Elem[])(r.length);
    // put everything in its place based on the counts.
    foreach (el; r.save)
    {
        res[counts[b(el)]++] = el;
    }

    // sort each bin separately.
    // if shift is 0 then each bin is uniform, so no need to sort them
    static if (scaling != Scaling.none)
    {
        // the last count will have overflowed when IndexElem is at the limit (IndexElem.max == r.length - 1)
        auto firstCount = (counts.length == 1) ? r.length : counts[0];
        res[0 .. firstCount].customSort!("a < b", ss)();
        foreach (i; 1 .. counts.length - 1)
        {
            res[counts[i - 1] .. counts[i]].customSort!("a < b", ss)();
        }
        if (counts.length != 1)
        {
            res[counts[$ - 2] .. $].customSort!("a < b", ss)();
        }
    }

    return res;
}

import phobossort : sort;

alias customSort = sort;
//alias customSort = sortIfNecessary;
//alias customSort = sortIfNecessary2;

pragma(inline, true)
auto sortIfNecessary(alias less = "a < b", SwapStrategy ss, R)(R r) {
    import std.range : assumeSorted;
    import phobossort : sort;

    foreach (i; 1 .. r.length) {
        if (r[i - 1] > r[i]) {
            r.sort!(less, ss)();
            return;
        }
    }
}

pragma(inline, true)
auto sortIfNecessary2(alias less = "a < b", SwapStrategy ss, R)(R r) {
    import std.range : assumeSorted;
    import phobossort : sort;
    import std.algorithm : swap, min;

    r[0 .. min(3, r.length)].sort!(less, ss)();
    foreach (i; 3 .. r.length) {
        if (r[i - 2] > r[i]) {
            r.sort!(less, ss)();
            return;
        }
        if (r[i - 1] > r[i]) {
            swap(r[i - 1], r[i]);
        }
    }
}