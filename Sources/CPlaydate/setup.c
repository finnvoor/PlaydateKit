
#include "pd_api.h"

typedef int (PDEventHandler)(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg);

extern PDEventHandler eventHandler;

static void* (*pdrealloc)(void* ptr, size_t size);
static void (*pdlogToConsole)(const char* fmt, ...);

int eventHandlerShim(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg)
{
    if ( event == kEventInit )
    {
        pdrealloc = playdate->system->realloc;
        pdlogToConsole = playdate->system->logToConsole;
    }
    
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

// Embedded Swift platform abstraction layer (see <swift/EmbeddedPlatform.h> in the toolchain), required by
// toolchains from 2026-10 onwards. Alignment is ignored, matching posix_memalign above.
#define SWIFT_ALLOC_ZERO_MEMORY 0x01

void* _swift_allocate(size_t alignment, size_t size, unsigned long long flags) {
    void *ptr = pdrealloc(NULL, size);
    if (ptr && (flags & SWIFT_ALLOC_ZERO_MEMORY)) __builtin_memset(ptr, 0, size);
    return ptr;
}
void _swift_deallocate(void* ptr, size_t alignment, size_t size, unsigned long long flags) { if ( ptr != NULL ) pdrealloc(ptr,0); }

void* _swift_typedAllocate(size_t size, size_t alignment, unsigned long long flags, unsigned long long typeId) {
    return _swift_allocate(alignment, size, flags);
}
void _swift_typedDeallocate(void* ptr, size_t size, size_t alignment, unsigned long long flags, unsigned long long typeId) {
    _swift_deallocate(ptr, alignment, size, flags);
}

// The Playdate runs Swift on a single thread, so the standard output lock is a no-op.
void _swift_lockStandardOutput(void) {}
void _swift_unlockStandardOutput(void) {}

// logToConsole always appends a newline, so output is buffered until a full line is written.
// See https://devforum.play.date/t/logtoconsole-without-a-linebreak/1819
static char stdoutBuffer[256];
static size_t stdoutBufferCount = 0;

static void flushStandardOutput(void) {
    stdoutBuffer[stdoutBufferCount] = 0;
    pdlogToConsole("%s", stdoutBuffer);
    stdoutBufferCount = 0;
}

size_t _swift_writeToStandardOutput(const unsigned char* chars, size_t count) {
    for (size_t i = 0; i < count; i++) {
        if (chars[i] == '\n') {
            flushStandardOutput();
        } else {
            if (stdoutBufferCount == sizeof(stdoutBuffer) - 1) flushStandardOutput();
            stdoutBuffer[stdoutBufferCount++] = chars[i];
        }
    }
    return count;
}

static const char* errorKindDescription(unsigned long long flags) {
    switch (flags & 0xFF) {
        case 1: return "Precondition failed";
        case 2: return "Assertion failed";
        default: return "Fatal error";
    }
}

void _swift_reportError(const unsigned char* message, size_t messageCount, unsigned long long flags) {
    pdlogToConsole("%s: %.*s", errorKindDescription(flags), (int)messageCount, message);
}

void _swift_reportErrorAt(
    const unsigned char* message, size_t messageCount,
    const unsigned char* fileName, size_t fileNameCount,
    size_t line, unsigned long long flags
) {
    pdlogToConsole("%.*s:%d: %s: %.*s", (int)fileNameCount, fileName, (int)line,
                   errorKindDescription(flags), (int)messageCount, message);
}

void _swift_generateRandom(void* buffer, size_t nbytes) {
    unsigned char* bytes = buffer;
    for (size_t i = 0; i < nbytes; i++) bytes[i] = rand() & 0xFF;
}
void _swift_generateRandomHashSeed(void* buffer, size_t nbytes) { _swift_generateRandom(buffer, nbytes); }

void *swift_coroFrameAlloc(size_t bytes, unsigned long long typeId) { return pdrealloc(NULL,bytes); }

// Wrappers for rand/srand. On macOS 16+, the SDK marks these
// __swift_unavailable but they're still callable from C.
int pd_rand(void) { return rand(); }
void pd_srand(unsigned int seed) { srand(seed); }
