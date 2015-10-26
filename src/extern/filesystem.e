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
expanded class FILESYSTEM
   --
   -- A façade to the actual filesystem implementation
   --

insert
   TEST_FACADE[FILESYSTEM_DEF]

feature {ANY} -- Files
   file_exists (path: ABSTRACT_STRING): BOOLEAN
      require
         path /= Void
      do
         Result := def.file_exists(path)
      end

   last_change_of (path: ABSTRACT_STRING): TIME
      require
         path /= Void
      do
         Result := def.last_change_of(path)
      end

   delete (path: ABSTRACT_STRING)
      require
         path /= Void
      do
         def.delete(path)
      end

   rename_to (old_path, new_path: ABSTRACT_STRING)
      require
         old_path /= Void
         new_path /= Void
      do
         def.rename_to(old_path, new_path)
      end

   copy_to (source_path, target_path: ABSTRACT_STRING)
      require
         source_path /= Void
         target_path /= Void
      do
         def.copy_to(source_path, target_path)
      end

   connect_read (path: ABSTRACT_STRING): TERMINAL_INPUT_STREAM
      require
         path /= Void
      do
         Result := def.connect_read(path)
      ensure
         Result /= Void implies Result.is_connected
      end

   connect_write (path: ABSTRACT_STRING): TERMINAL_OUTPUT_STREAM
      require
         path /= Void
      do
         Result := def.connect_write(path)
      ensure
         Result /= Void implies Result.is_connected
      end

   connect_read_write (path: ABSTRACT_STRING): TERMINAL_INPUT_OUTPUT_STREAM
      require
         path /= Void
      do
         Result := def.connect_read_write(path)
      ensure
         Result /= Void implies Result.is_connected
      end

feature {ANY} -- Directories
   is_directory (path: ABSTRACT_STRING): BOOLEAN
      require
         path /= Void
      do
         Result := def.is_directory(path)
      end

   create_new_directory (path: ABSTRACT_STRING): BOOLEAN
      require
         path /= Void
      do
         Result := def.create_new_directory(path)
      end

feature {}
   def_impl: FILESYSTEM_IMPL
      once
         create Result
      end

end -- class FILESYSTEM
