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
expanded class BZERO

insert
   STRING_HANDLER

feature {ANY}
   secure_clean alias "()" (s: STRING)
         -- Cleans up the string in constant time.
      require
         s.capacity > 0
         s.capacity <= secure_max(s.capacity)
      local
         c: INTEGER
      do
         s.clear_count
         c := secure_max(s.capacity)
         bzero(s.storage, s.capacity)
      ensure
         s.is_empty
         s.storage.occurrences('%U', s.capacity) = s.capacity
      end

   secure_max (c: INTEGER): INTEGER
         -- The maximum secure capacity
      external "plug_in"
      alias "[
         location: "."
         module_name: "plugin"
         feature_name: "max_bzero"
      ]"
      end

feature {}
   bzero (buf: NATIVE_ARRAY[CHARACTER]; count: INTEGER)
         -- Put `count` '%U' characters in `buf`, in a constant time.
      require
         count > 0
      external "plug_in"
      alias "[
         location: "."
         module_name: "plugin"
         feature_name: "force_bzero"
      ]"
      end

end -- class BZERO
