-- This file is part of pwd.
-- Copyright (C) 2012-2014 Cyril Adrian <cyril.adrian@gmail.com>
--
-- pwd is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, version 3 of the License.
--
-- pwd is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with pwd.  If not, see <http://www.gnu.org/licenses/>.
--
class TEST_PASS_GENERATOR_RANDOM_01

insert
   PWD_TEST
   PASS_GENERATOR_PARSER_CONSTANTS

create {}
   test

feature {}
   test
      local
         gen: PASS_GENERATOR_RANDOM; file: BINARY_FILE_READ
      do
         create file.connect_to(random_file)
         create gen.connect_to(file)

         assert(gen.is_connected)

         assert(gen.item(1, 4).in_range(1, 4))
         assert(gen.item(2, 37).in_range(2, 37))
         assert(gen.item(32, 127).in_range(32, 127))
         assert(gen.item(13, 7442).in_range(13, 7442))
      end

   random_file: STRING "pwd_test.e"
         -- who cares, it just needs to exist

end -- class TEST_PASS_GENERATOR_RANDOM_01
