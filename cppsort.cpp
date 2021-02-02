#include <algorithm>
#include <stdint.h>

struct Slice {
    size_t length;
    int32_t *ptr;
};

extern "C" Slice cppSortImpl(Slice r) {
    std::sort(r.ptr, r.ptr + r.length);
    return r;
}
