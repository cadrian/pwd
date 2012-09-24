/* includes */
#if defined __USE_POSIX || defined __unix__ || defined _POSIX_C_SOURCE || defined __APPLE__
#elif defined WIN32
#else
#endif

/* is native? */
int xclip_native(void) {
#if defined __USE_POSIX || defined __unix__ || defined _POSIX_C_SOURCE || defined __APPLE__
     return 0; /* not yet implemented */
#elif defined WIN32
     return 0; /* not yet implemented */
#else
     return 0;
#endif
}

/* the actual clipboard copy */
void xclip_copy(void *string) {
#if defined __USE_POSIX || defined __unix__ || defined _POSIX_C_SOURCE || defined __APPLE__
     /* not yet implemented */
#elif defined WIN32
     /* not yet implemented */
#else
     /* must not happen => ugly crash */
     int*p=0;*p=0;
#endif
}
