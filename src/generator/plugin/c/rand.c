static uint8_t rand_bit(uint8_t (*rand_fn)(void*), void*data) {
   static uint8_t count = 0;
   static uint8_t byte;
   uint8_t result;
   if (count == 0) {
      byte = rand_fn(data);
      count = 8;
   }
   result = byte & 1;
   byte >>= 1;
   return result;
}

uint32_t randi(uint32_t range, uint8_t (*rand_fn)(void*), void*data) {
   uint32_t result = 0;
   while (range) {
      result = (result << 1) | rand_bit(rand_fn, data);
      range >>= 1;
   }
   return result % range;
}
