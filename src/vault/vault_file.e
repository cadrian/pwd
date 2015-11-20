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
   -- The abstraction of a vault file.
   --

feature {ANY}
   load (loader: FUNCTION[TUPLE[INPUT_STREAM], ABSTRACT_STRING]): ABSTRACT_STRING
         -- Load the file. Returns an empty string on success, the
         -- error message otherwise.
         -- The `loader' must ensure to return a non-Void string
         -- (also empty on success).
      require
         loader /= Void
         is_open
      deferred
      ensure
         Result /= Void
      end

   save (stream: INPUT_STREAM; on_save: FUNCTION[TUPLE[ABSTRACT_STRING], ABSTRACT_STRING]): ABSTRACT_STRING
         -- Save the file. Returns an empty string on success, the
         -- error message otherwise.
         -- The `on_save` hook will return an empty string on success;
         -- on otherwise, the file is expected to be reverted in its
         -- previous sensible state.
      require
         stream.is_connected
         on_save /= Void
         is_open
      deferred
      ensure
         Result /= Void
      end

   is_open: BOOLEAN
      deferred
      end

   close
      deferred
      ensure
         not is_open
      end

end -- class VAULT_FILE
