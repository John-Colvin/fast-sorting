module othersorts;
import std.format : format;

pragma(inline, false)
Elem[] phobosSort(Elem)(Elem[] r) {
    import phobossort: sort;
    r.sort();
    return r;
}

static foreach (name; ["cpp", "kx", "boost"]) {
    mixin(name.format!q{
        private extern (C) int[] %1$sSortImpl32(int[] r);
        private extern (C) long[] %1$sSortImpl64(long[] r);

        pragma(inline, false)
        Elem[] %1$sSort(Elem)(Elem[] r) {
            static if (is(Elem == int)) {
                return %1$sSortImpl32(r);
            } else static if(is(Elem == long)) {
                return %1$sSortImpl64(r);
            } else static assert(false, "Unsupported type" ~ Elem.stringof);
        }
    });
}
