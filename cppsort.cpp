#include <algorithm>
#include <stdint.h>
#include "kxsort.h"
#include <boost/sort/spreadsort/integer_sort.hpp>

#define Slice(N) struct Slice##N { size_t length; int##N##_t *ptr; };

Slice(16)
Slice(32)
Slice(64)

#define sort(theSort, name, N) \
extern "C" Slice##N name##SortImpl##N(Slice##N r) { \
    theSort(r.ptr, r.ptr + r.length);  \
    return r; \
}

sort(std::sort, cpp, 16)
sort(std::sort, cpp, 32)
sort(std::sort, cpp, 64)
sort(kx::radix_sort, kx, 16)
sort(kx::radix_sort, kx, 32)
sort(kx::radix_sort, kx, 64)
sort(boost::sort::spreadsort::integer_sort, boost, 16)
sort(boost::sort::spreadsort::integer_sort, boost, 32)
sort(boost::sort::spreadsort::integer_sort, boost, 64)
