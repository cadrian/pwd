#pragma GCC push_options
#pragma GCC optimize ( "-O0" )

/*
 * Try to be really sure that the compiler does not optimize this.
 */
__attribute__ (( noinline )) void force_bzero(char*buf, int count) {
     volatile char* data = (volatile char*)buf;
     volatile int i;
     for (i = count; i --> 0; ) {
          data[i] = '\0';
     }
}

#pragma GCC pop_options
