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
deferred class FILESYSTEM_DEF

inherit
   TESTABLE

feature {FILESYSTEM} -- Files
   file_exists (path: ABSTRACT_STRING): BOOLEAN
      require
         path /= Void
      deferred
      end

   last_change_of (path: ABSTRACT_STRING): TIME
      require
         path /= Void
      deferred
      end

   delete (path: ABSTRACT_STRING)
      require
         path /= Void
      deferred
      end

   rename_to (old_path, new_path: ABSTRACT_STRING)
      require
         old_path /= Void
         new_path /= Void
      deferred
      end

   copy_to (source_path, target_path: ABSTRACT_STRING)
      require
         source_path /= Void
         target_path /= Void
      deferred
      end

   read_text (path: ABSTRACT_STRING): TERMINAL_INPUT_STREAM
      require
         path /= Void
      deferred
      ensure
         Result /= Void implies Result.is_connected
      end

   write_text (path: ABSTRACT_STRING): TERMINAL_OUTPUT_STREAM
      require
         path /= Void
      deferred
      ensure
         Result /= Void implies Result.is_connected
      end

   read_write_text (path: ABSTRACT_STRING): TERMINAL_INPUT_OUTPUT_STREAM
      require
         path /= Void
      deferred
      ensure
         Result /= Void implies Result.is_connected
      end

   read_binary (path: ABSTRACT_STRING): BINARY_INPUT_STREAM
      require
         path /= Void
      deferred
      ensure
         Result /= Void implies Result.is_connected
      end

   write_binary (path: ABSTRACT_STRING): BINARY_OUTPUT_STREAM
      require
         path /= Void
      deferred
      ensure
         Result /= Void implies Result.is_connected
      end

feature {ANY} -- Directories
   is_directory (path: ABSTRACT_STRING): BOOLEAN
      require
         path /= Void
      deferred
      end

   create_new_directory (path: ABSTRACT_STRING): BOOLEAN
      require
         path /= Void
      deferred
      end

end -- class FILESYSTEM_DEF
