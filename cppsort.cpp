#include <algorithm>
#include <stdint.h>
#include "kxsort.h"
#include <boost/sort/spreadsort/integer_sort.hpp>

struct Slice {
    size_t length;
    int32_t *ptr;
};

extern "C" Slice cppSortImpl(Slice r) {
    std::sort(r.ptr, r.ptr + r.length);
    return r;
}

extern "C" Slice kxSortImpl(Slice r) {
    kx::radix_sort(r.ptr, r.ptr + r.length);
    return r;
}

extern "C" Slice boostSortImpl(Slice r) {
    boost::sort::spreadsort::integer_sort(r.ptr, r.ptr + r.length);
    return r;
}
