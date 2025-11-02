#include <stdlib.h>
#include <stdint.h>
#include <errno.h>

int posix_memalign(void **memptr, size_t alignment, size_t size) {
  *memptr = aligned_alloc(alignment, size);
  return (*memptr == NULL) ? ENOMEM : 0;
}
