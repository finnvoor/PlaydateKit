
#include "pd_api.h"

typedef int (PDEventHandler)(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg);

extern PDEventHandler eventHandler;

static void* (*pdrealloc)(void* ptr, size_t size);

int eventHandlerShim(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg)
{
    if ( event == kEventInit )
        pdrealloc = playdate->system->realloc;
    
    return eventHandler(playdate, event, arg);
}

#if TARGET_PLAYDATE

void* _malloc_r(struct _reent* _REENT, size_t nbytes) { return pdrealloc(NULL,nbytes); }
void* _realloc_r(struct _reent* _REENT, void* ptr, size_t nbytes) { return pdrealloc(ptr,nbytes); }
void _free_r(struct _reent* _REENT, void* ptr ) { if ( ptr != NULL ) pdrealloc(ptr,0); }

// Newlib syscall stubs required by the linker on bare-metal ARM.
int getentropy(void *buffer, size_t length) { return -1; }
int _getentropy(void *buffer, size_t length) { return -1; }
int _kill(int pid, int sig) { return -1; }
int _getpid(void) { return 1; }
int _close(int fd) { return -1; }
int _lseek(int fd, int offset, int whence) { return -1; }
int _read(int fd, void *buf, int count) { return -1; }
int _write(int fd, const void *buf, int count) { return -1; }
int _fstat(int fd, void *buf) { return -1; }
int _isatty(int fd) { return 0; }

#else

void* malloc(size_t nbytes) { return pdrealloc(NULL,nbytes); }
void* realloc(void* ptr, size_t nbytes) { return pdrealloc(ptr,nbytes); }
void  free(void* ptr ) { if ( ptr != NULL ) pdrealloc(ptr,0); }

#endif

int posix_memalign(void **memptr, size_t alignment, size_t size) {
    void *ptr = pdrealloc(NULL, size);
    if (!ptr) return 12; // ENOMEM
    *memptr = ptr;
    return 0;
}

void *swift_coroFrameAlloc(size_t bytes, unsigned long long typeId) { return pdrealloc(NULL,bytes); }

// Wrappers for rand/srand. On macOS 16+, the SDK marks these
// __swift_unavailable but they're still callable from C.
int pd_rand(void) { return rand(); }
void pd_srand(unsigned int seed) { srand(seed); }
