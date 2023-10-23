module exampledata;

auto dataGenerator(Elem)(string pattern, size_t len) {
    import std.algorithm : map, joiner, sum, cumulativeFold;
    import std.array : array;
    import std.conv : to;
    import std.random : uniform, uniform01, choice;
    import std.range : iota, retro, cycle, drop, dropOne, takeExactly, chain, repeat, only;
    switch(pattern) {
        case "Uniform":
            return () => iota(len).map!(i => uniform(Elem(0), 1000.to!Elem)).array;
            break;
        case "UniformEqualRange":
            return () => iota(len).map!(i => uniform(Elem(0), len.to!Elem)).array;
            break;
        case "UniformFullRange":
            return () => iota(len).map!(i => uniform(Elem.min, Elem.max)).array;
            break;
        case "Squared":
            return () => iota(len).map!(i => uniform(Elem(0), len.to!Elem / 100)^^2).array;
            break;
        case "SmoothPow4":
            return () => iota(len).map!(i => (uniform(0.0, 20.0)^^4).to!Elem).array;
            break;
        case "Forward":
            return () => iota(len).map!(i => i.to!Elem).array;
            break;
        case "Reverse":
            return () => iota(len).map!(i => i.to!Elem).retro.array;
            break;
        case "Comb":
            return () => iota(len).map!(i => (i + ((i & 1) ? len / 2 : 0)).to!Elem).array;
            break;
        case "ReverseComb":
            return () => iota(len).map!(i => (i + ((i & 1) ? len / 2 : 0)).to!Elem).retro.array;
            break;
        case "RandomBinary":
            return () => iota(len).map!(i => choice([Elem(0), Elem(1)])).array;
            break;
        case "RandomBigBinary":
            return () => iota(len).map!(i => choice([Elem.max / 2, Elem.max])).array;
            break;
        case "OrganPipe":
            return () => iota((len / 2).to!Elem).chain((len & 1) ? [(1 + len / 2).to!Elem] : [], iota((len / 2).to!Elem).retro).array;
            break;
        case "MinAtBack":
            return () => iota(len).map!(i => i.to!Elem).cycle.dropOne.takeExactly(len).array;
            break;
        case "MaxAtFront":
            return () => iota(len).map!(i => i.to!Elem).cycle.drop(len - 1).takeExactly(len).array;
            break;
        case "FlatSpike":
            return () => chain([0, Elem(10_000)], repeat(0, len - 2)).array;
            break;
        case "RampSpike":
            return () => chain([(len * 10).to!Elem], iota((len - 1).to!Elem)).array;
            break;
        case "Sequences":
            return () => iota(10)
                            .map!((i) { auto base = uniform(Elem(0), Elem(len)); return iota(base, base + Elem(len / 10)); })
                            .joiner.array;
        case "ReverseSequences":
            return () => iota(10)
                            .map!((i) { auto base = uniform(Elem(0), Elem(len)); return iota(base, base + Elem(len / 10)).retro; })
                            .joiner.array;
        case "PdfSpikes":
            return () => iota(len).map!(i => choice(only(10, 80)) * iota(100).map!(_ => uniform01()).sum.to!Elem).array;
        case "PdfSpikeClusters":
            return () => iota(len).cumulativeFold!((a, b) {
                const sample = uniform01();
                return a ? (sample > 0.05) : (sample > 0.95);
            })(false)
                .map!(i => only(10, 80)[i] * iota(100).map!(_ => uniform01()).sum.to!Elem).array;
        default:
            throw new Exception("did not recognise data pattern name \"" ~ pattern ~ "\"");
    }
}
