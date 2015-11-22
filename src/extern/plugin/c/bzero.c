#pragma GCC push_options
#pragma GCC optimize ( "-O0" )

static volatile int __bzero_max = 1024;

/*
 * Try to be really sure that the compiler does not optimize this:
 *  - force -O0
 *  - reverse loop to force cache misses
 *  - at least __bzero_max loops; so this should be safe if count < __bzero_max
 */
__attribute__ (( noinline )) void force_bzero(char*buf, int count) {
   volatile char* data = (volatile char*)buf;
   volatile int i;
   volatile int max = count > __bzero_max ? count : __bzero_max;
   for (i = max; i --> 0; ) {
      data[i % count] = '\0';
   }
}

__attribute__ (( noinline )) int max_bzero(int count) {
   volatile int result = __bzero_max;
   volatile int r;
   volatile int i;
   for (i = 0; i < 16; i++) {
      if (result < count) {
         r = result * 2;
         if (r > result) {
            result = r; // beware of overflows
         }
      }
   }
   __bzero_max = result;
   return result;
}

#pragma GCC pop_options
