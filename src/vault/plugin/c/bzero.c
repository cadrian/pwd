#pragma GCC push_options
#pragma GCC optimize ( "-O0" )

#define MAX_BZERO 16384

/*
 * Try to be really sure that the compiler does not optimize this:
 *  - force -O0
 *  - reverse loop to force cache misses
 *  - at least MAX_BZERO loops; so this should be safe if count < MAX_BZERO
 */
__attribute__ (( noinline )) void force_bzero(char*buf, int count) {
     volatile char* data = (volatile char*)buf;
     volatile int i;
     volatile int max = count > MAX_BZERO ? count : MAX_BZERO;
     for (i = max; i --> 0; ) {
          data[i % count] = '\0';
     }
}

#undef MAX_BZERO

#pragma GCC pop_options
