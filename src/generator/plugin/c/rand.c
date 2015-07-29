/**
 * Copied from http://allendowney.com/research/rand/downey07randfloat.pdf
 */

/* BOX: this union is used to access the bits
   of real32_ting-point values */
typedef union box {
     real32_t f;
     int32_t i;
} box_t;

uint32_t randi(uint8_t (*rand_fn)(void*), void*data) {
     return (uint32_t)(
          (rand_fn(data) << 24) |
          (rand_fn(data) << 16) |
          (rand_fn(data) <<  8) |
          (rand_fn(data))
     );
}
