#ifdef TARGET_PLAYDATE
  #include <stddef.h>
  extern void* malloc(size_t);
  extern void* realloc(void*, size_t);
  extern void  free(void*);
#else
  #include <stdlib.h>
#endif

void* lodepng_malloc(size_t size) { return malloc(size); }
void* lodepng_realloc(void* ptr, size_t size) { return realloc(ptr, size); }
void  lodepng_free(void* ptr) { free(ptr); }

