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
class FILESYSTEM_IMPL

inherit
   FILESYSTEM_DEF

feature {FILESYSTEM} -- Files
   file_exists (path: ABSTRACT_STRING): BOOLEAN
      do
         Result := file_tools.file_exists(path)
      end

   last_change_of (path: ABSTRACT_STRING): TIME
      do
         Result := file_tools.last_change_of(path)
      end

   delete (path: ABSTRACT_STRING)
      do
         file_tools.delete(path)
      end

   rename_to (old_path, new_path: ABSTRACT_STRING)
      do
         file_tools.rename_to(old_path, new_path)
      end

   copy_to (source_path, target_path: ABSTRACT_STRING)
      do
         file_tools.copy_to(source_path, target_path)
      end

   connect_read (path: ABSTRACT_STRING): TEXT_FILE_READ
      do
         create Result.connect_to(path)
         if not Result.is_connected then
            Result := Void
         end
      end

   connect_write (path: ABSTRACT_STRING): TEXT_FILE_WRITE
      do
         create Result.connect_to(path)
         if not Result.is_connected then
            Result := Void
         end
      end

   connect_read_write (path: ABSTRACT_STRING): TEXT_FILE_READ_WRITE
      do
         create Result.connect_to(path)
         if not Result.is_connected then
            Result := Void
         end
      end

feature {ANY} -- Directories
   is_directory (path: ABSTRACT_STRING): BOOLEAN
      do
         Result := file_tools.is_directory(path)
      end

   create_new_directory (path: ABSTRACT_STRING): BOOLEAN
      do
         Result := basic_directory.create_new_directory(path)
      end

feature {}
   file_tools: FILE_TOOLS
   basic_directory: BASIC_DIRECTORY

end -- class FILESYSTEM_IMPL
