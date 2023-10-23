module fastmakeindex;

import std.algorithm;
import std.range;
import std.traits;

void makeIndexLessIntegersOnly(
    SwapStrategy ss,
    Range,
    RangeIndex)
(scope Range r, scope RangeIndex index)
if (isRandomAccessRange!Range && !isInfinite!Range &&
    isRandomAccessRange!RangeIndex && !isInfinite!RangeIndex &&
    isIntegral!(ElementType!RangeIndex) && hasAssignableElements!RangeIndex &&
    isIntegral!(ElementType!Range))
{
    import std.meta : AliasSeq;
    import std.traits : Unsigned;

    alias Elem = ElementType!Range;

    if (r.empty) {
        return;
    }

    Unqual!Elem min = r[0], max = r[0];
    bool inOrder = true;
    foreach (i; 1 .. r.length)
    {
        const el = r[i];
        if (el < min)
            min = el;
        if (el > max)
            max = el;
        inOrder = inOrder & (r[i - 1] <= el);
    }
    if (inOrder)
    {
        // Use size_t as loop index to avoid overflow on ++i,
        // e.g. when squeezing 256 elements into a ubyte index.
        foreach (size_t i; 0 .. r.length)
            index[i] = cast(ElementType!RangeIndex) i;
        return;
    }

    // magic number that seems to work well. Results are mostly not that
    // sensitive to it though
    // 16 seems sensible idk
    enum targetNumPerBin = 10;
    // Divisor for the keys to decide which bin they go in, based on targetNumPerBin
    immutable k = targetNumPerBin * double(Unsigned!Elem(max) - min) / r.length;

    if (k >= 1.5)
    {
        makeIndexLessIntegersOnlyImpl!(Scaling.down, ss, Range, RangeIndex)(r, index, min, max, k);
    }
    else
    {
        makeIndexLessIntegersOnlyImpl!(Scaling.none, ss, Range, RangeIndex)(r, index, min, max, k);
    }
}

private enum Scaling {
    down,
    none
}

pragma(inline, false)
private void makeIndexLessIntegersOnlyImpl
    (Scaling scaling, SwapStrategy ss, Range, RangeIndex)
    (scope Range r, scope RangeIndex index, immutable ElementType!Range minVal,
    immutable ElementType!Range maxVal, immutable double k)
in (k > 0)
body {
    pragma(LDC_never_inline);
    import core.stdc.stdlib : calloc, free;
    import std.math : lround, log2;
    import std.traits : Unsigned;

    alias Elem = ElementType!Range;
    alias IndexElem = ElementType!RangeIndex;

    // Choose the bin, based on the key
    static if (scaling == Scaling.none)
    {
        debug(PrintInfo) const shift = 0;

        pragma(inline, true)
        IndexElem b(Elem x)
        {
            return cast(IndexElem) (Unsigned!Elem(x) - minVal);
        }
    }
    else static if (scaling == Scaling.down)
    {
        const shift = lround(log2(k));

        assert(shift > 0);
        pragma(inline, true)
        IndexElem b(Elem x)
        {
            return cast(IndexElem) ((Unsigned!Elem(x) - minVal) >> shift);
        }
    }
    else static assert(0);

    const nBins = (cast(size_t) b(maxVal)) + 1;

    debug(PrintInfo)
    {{
        import std.stdio : stderr;
        stderr.writeln("length: ", r.length, " scaling: ", scaling, " min: ", minVal, " max: ", maxVal, " k: ", k,
            " shift: ", shift, " nBins: ", nBins, " nPerBin: ", double(r.length) / nBins);
    }}

    pragma(inline, true)
    static IndexElem[] tmpMem(size_t nBins) @trusted
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
    scope counts = tmpMem(nBins);
    scope (exit)
        (() @trusted { free(counts.ptr); })();

    // count how many will go in each bin
    foreach (el; r.save)
    {
        counts[b(el)]++;
    }

    debug(PrintInfo)
    {{
        import std.algorithm : fold, min, max;
        import std.stdio : stderr;
        stderr.writeln("counts min: ", fold!min(counts), " counts max: ", fold!max(counts));
    }}

    // turn that in to a cumulative count starting at 0
    // the top count is lost from counts but that's implicit from the length of the input
    IndexElem total = 0;
    foreach (ref count; counts)
    {
        auto oldCount = count;
        count = total;
        total += oldCount;
    }

    // put everything in its place based on the counts.
    {
        IndexElem i = 0;
        foreach (el; r.save)
        {
            index[counts[b(el)]++] = i++;
        }
    }

    // sort each bin separately.
    // if shift is 0 then each bin is uniform, so no need to sort them
    static if (scaling != Scaling.none)
    {
        // the last count will have overflowed when IndexElem is at the limit (IndexElem.max == r.length - 1)
        auto firstCount = (counts.length == 1) ? index.length : counts[0];
        index[0 .. firstCount].sort!((a, b) => r[a] < r[b], ss)();
        foreach (i; 1 .. counts.length - 1)
        {
            index[counts[i - 1] .. counts[i]].sort!((a, b) => r[a] < r[b], ss)();
        }
        if (counts.length != 1)
        {
            index[counts[counts.length - 2] .. index.length].sort!((a, b) => r[a] < r[b], ss)();
        }
    }
}
