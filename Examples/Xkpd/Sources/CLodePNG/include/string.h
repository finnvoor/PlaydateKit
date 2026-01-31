// https://discord.com/channels/675983554655551509/1217244550666518589/1383869527800152244

#ifndef _STRING_H
#define _STRING_H

#include <stddef.h>

void *memset(void *, int, size_t);
void *memcpy(void *, const void *, size_t);
void *memmove(void *, const void *, size_t);
int memcmp(const void *, const void *, size_t);
size_t strlen(const char *);
int strcmp(const char *, const char *);

#endif
