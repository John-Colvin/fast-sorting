#include <algorithm>
#include <stdint.h>
#include "kxsort.h"
#include <boost/sort/spreadsort/integer_sort.hpp>

struct Slice32 {
    size_t length;
    int32_t *ptr;
};

struct Slice64 {
    size_t length;
    int64_t *ptr;
};

extern "C" Slice32 cppSortImpl32(Slice32 r) {
    std::sort(r.ptr, r.ptr + r.length);
    return r;
}

extern "C" Slice32 kxSortImpl32(Slice32 r) {
    kx::radix_sort(r.ptr, r.ptr + r.length);
    return r;
}

extern "C" Slice32 boostSortImpl32(Slice32 r) {
    boost::sort::spreadsort::integer_sort(r.ptr, r.ptr + r.length);
    return r;
}

extern "C" Slice64 cppSortImpl64(Slice64 r) {
    std::sort(r.ptr, r.ptr + r.length);
    return r;
}

extern "C" Slice64 kxSortImpl64(Slice64 r) {
    kx::radix_sort(r.ptr, r.ptr + r.length);
    return r;
}

extern "C" Slice64 boostSortImpl64(Slice64 r) {
    boost::sort::spreadsort::integer_sort(r.ptr, r.ptr + r.length);
    return r;
}

