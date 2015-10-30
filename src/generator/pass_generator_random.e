-- This file is part of pwd.
-- Copyright (C) 2012-2015 Cyril Adrian <cyril.adrian@gmail.com>
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
class PASS_GENERATOR_RANDOM

insert
   LOGGING

create {ANY}
   connect_to

feature {ANY}
   is_connected: BOOLEAN
      do
         Result := file.is_connected
      end

   disconnect
      require
         is_connected
      do
         file.disconnect
      end

   path: STRING

   item (lower, upper: INTEGER_32): INTEGER_32
      require
         lower >= 0
         dont_waste_entropy: upper > lower
         is_connected
      do
         Result := randi((upper - lower + 1).to_natural_32, $read_rand, to_pointer).to_integer_32 + lower
      ensure
         Result.in_range(lower, upper)
      end

feature {}
   randi (range: NATURAL_32; fun, obj: POINTER): NATURAL_32
      external "plug_in"
      alias "[
         location: "."
         module_name: "plugin"
         feature_name: "randi"
      ]"
      end

   read_rand: NATURAL_8
      do
         file.read_byte
         Result := file.last_byte.to_natural_8
      end

   file: BINARY_INPUT_STREAM

feature {}
   connect_to (a_path: ABSTRACT_STRING)
      require
         a_path /= Void
      do
         path := a_path.out
         file := filesystem.read_binary(path)
      ensure
         path.is_equal(a_path)
      end

   filesystem: FILESYSTEM

invariant
   path /= Void
   file /= Void

end -- class PASS_GENERATOR_RANDOM
