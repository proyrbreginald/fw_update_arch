#include <stdint.h>
#include <stddef.h>

void *memset(void *s, int v, size_t n)
{
    uint8_t *p = (uint8_t *)s;
    while (n--)
    {
        *p++ = (uint8_t)v;
    }
    return s;
}