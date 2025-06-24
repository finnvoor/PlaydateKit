#ifdef TARGET_PLAYDATE
  extern void* pdrealloc(void* ptr, size_t size);
  void* lodepng_malloc(size_t size) { return pdrealloc(NULL, size); }
  void* lodepng_realloc(void* ptr, size_t size) { return pdrealloc(ptr, size); }
  void  lodepng_free(void* ptr) { if(ptr) pdrealloc(ptr, 0); }
#else
  #include <stdlib.h>
  void* lodepng_malloc(size_t size) { return malloc(size); }
  void* lodepng_realloc(void* ptr, size_t size) { return realloc(ptr, size); }
  void  lodepng_free(void* ptr) { free(ptr); }
#endif

