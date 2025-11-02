#include <stdlib.h>
#include <stdint.h>
#include <errno.h>

int posix_memalign(void **memptr, size_t alignment, size_t size) {
  if (alignment < sizeof(void *) || (alignment & (alignment - 1)) != 0) {
    return EINVAL;
  }
  
  // aligned_alloc requires size to be a multiple of alignment
  size_t adjusted_size = (size + alignment - 1) & ~(alignment - 1);
  
  *memptr = aligned_alloc(alignment, adjusted_size);
  
  return (*memptr == NULL) ? ENOMEM : 0;
}
