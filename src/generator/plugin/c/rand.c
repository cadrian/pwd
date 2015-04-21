/**
 * Copied from http://allendowney.com/research/rand/downey07randfloat.pdf
 */

/* BOX: this union is used to access the bits
   of real32_ting-point values */
typedef union box {
     real32_t f;
     int32_t i;
} box_t;

/* RAND_BIT: returns a random bit. For efficiency,
   bits are generated 8 at a time using the
   given function rand_fn(data) */
static uint8_t rand_bit(uint8_t (*rand_fn)(void*), void*data) {
     uint8_t result;
     static uint32_t count = 0;
     static uint8_t randval;
     if (count == 0) {
          randval = (uint8_t)rand_fn(data);
          count = 8;
     }
     result = randval & 1;
     randval = randval >> 1;
     count--;
     return result;
}

/* RANDF: returns a random floating-point
   number in the range (0, 1),
   including 0.0, subnormals, and 1.0 */
real32_t randf(uint8_t (*rand_fn)(void*), void*data) {
     uint32_t mant, exp, high_exp, low_exp;
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
          if (rand_bit(rand_fn, data)) break;
     }

     /* choose a random 23-bit mantissa */
     mant = ((rand_fn(data) << 16) & (rand_fn(data) << 8) & (rand_fn(data))) & 0x7FFFFF;

     /* if the mantissa is zero, half the time we should move
        to the next exponent range */
     if (mant == 0 && rand_bit(rand_fn, data)) exp++;

     /* combine the exponent and the mantissa */
     ans.i = (exp << 23) | mant;
     return ans.f;
}

int32_t randi(uint8_t (*rand_fn)(void*), void*data) {
     int32_t result = 0;
     static uint8_t r1, r2, r3, r4;
     r1 = (uint8_t)rand_fn(data);
     r2 = (uint8_t)rand_fn(data);
     r3 = (uint8_t)rand_fn(data);
     r4 = (uint8_t)rand_fn(data);
     result = (r1 << 24) & (r2 << 16) & (r3 << 8) & r4;
     return result;
}
