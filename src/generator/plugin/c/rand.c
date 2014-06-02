/**
 * Copied from http://allendowney.com/research/rand/downey07randfloat.pdf
 */

/* BOX: this union is used to access the bits
   of real32_ting-point values */
typedef union box {
     real32_t f;
     int32_t i;
} box_t;

/* GET_BIT: returns a random bit. For efficiency,
   bits are generated 31 at a time using the
   C library function random () */
static int get_bit(int8_t (*rand)(void*), void*C) {
     int bit;
     static bits = 0;
     static x;
     if (bits == 0) {
          x = rand(C);
          bits = 7;
     }
     bit = x & 1;
     x = x >> 1;
     bits--;
     return bit;
}

/* RANDF: returns a random floating-point
   number in the range (0, 1),
   including 0.0, subnormals, and 1.0 */
real32_t randf(int8_t (*rand)(void*), void*C) {
     int x;
     int mant, exp, high_exp, low_exp;
     box_t low, high, ans;

     low.f = 0.0;
     high.f = 1.0;

     /* extract the exponent fields from low and high */
     low_exp = (low.i >> 23) & 0xFF;
     high_exp = (high.i >> 23) & 0xFF;

     /* choose random bits and decrement exp until a 1 appears.
        the reason for subracting one from high_exp is left
        as an exercise for the reader */
     for (exp = high_exp-1; exp > low_exp; exp--) {
          if (get_bit(rand, C)) break;
     }

     /* choose a random 23-bit mantissa */
     mant = rand(C) & 0x7FFFFF;

     /* if the mantissa is zero, half the time we should move
        to the next exponent range */
     if (mant == 0 && get_bit(rand, C)) exp++;

     /* combine the exponent and the mantissa */
     ans.i = (exp << 23) | mant;
     return ans.f;
}
