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
deferred class VAULT_FILE
   --
   -- The abstraction of vault file.
   --

feature {ANY}
   load (keys: DICTIONARY[KEY, FIXED_STRING]; vault_io: VAULT_IO): ABSTRACT_STRING
         -- Load the keys from `vault_io' into `keys'. No merging is
         -- performed; the `keys' dictionary is not expected to
         -- contain data.
         -- Returns an empty string on success, the error message otherwise.
      require
         keys.is_empty
         vault_io /= Void
      deferred
      ensure
         Result /= Void
      end

   save (keys: DICTIONARY[KEY, FIXED_STRING]; vault_io: VAULT_IO): ABSTRACT_STRING
         -- Save the `keys' using `vault_io'.
         -- Returns an empty string on success, the error message otherwise.
      require
         keys /= Void
         vault_io /= Void
      deferred
      ensure
         Result /= Void
      end

end -- class VAULT_FILE
