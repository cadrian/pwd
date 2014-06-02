-- This file is part of pwdmgr.
-- Copyright (C) 2012-2014 Cyril Adrian <cyril.adrian@gmail.com>
--
-- pwdmgr is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, version 3 of the License.
--
-- pwdmgr is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with pwdmgr.  If not, see <http://www.gnu.org/licenses/>.
--
class PASS_GENERATOR_RANDOM

create {ANY}
   connect_to

feature {ANY}
   is_connected: BOOLEAN is
      do
         Result := file.is_connected
      end

   path: STRING is
      do
         Result := file.path
      end

   item (lower, upper: INTEGER_32): INTEGER_32 is
      require
         lower >= 0
         upper > lower
         is_connected
      do
         Result := (randf($read_rand, to_pointer) * (upper - lower).to_real_32 + {REAL_32 0.5}).force_to_integer_32 + lower
      ensure
         Result.in_range(lower, upper)
      end

feature {}
   randf (fun, obj: POINTER): REAL_32 is
      external "plug_in"
      alias "[
         location: "."
         module_name: "plugin"
         feature_name: "randf"
      ]"
      end

   read_rand: INTEGER_8 is
      do
         file.read_byte
         Result := file.last_byte.to_integer_8
      end

   file: BINARY_FILE_READ

feature {}
   connect_to (a_file: like file) is
      require
         a_file.is_connected
      do
         file := a_file
      ensure
         file = a_file
      end

end
