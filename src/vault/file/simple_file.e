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
class SIMPLE_FILE

inherit
   VAULT_FILE

insert
   LOGGING

create {ANY}
   make

feature {ANY}
   load (loader: FUNCTION[TUPLE[INPUT_STREAM], ABSTRACT_STRING]): ABSTRACT_STRING
      local
         in: INPUT_STREAM
      do
         in := filesystem.read_text(filename)
         if in.is_connected then
            Result := loader.item([in])
            in.disconnect
         else
            Result := once "Could not read file #(1)" # filename
         end
      end

   save (stream: INPUT_STREAM; on_save: FUNCTION[TUPLE[ABSTRACT_STRING], ABSTRACT_STRING]): ABSTRACT_STRING
      local
         tfw: OUTPUT_STREAM; backup: ABSTRACT_STRING
      do
         backup := "#(1)~" # filename
         filesystem.copy_to(filename, backup)

         tfw := filesystem.write_text(filename)
         if tfw.is_connected then
            extern.splice(stream, tfw)
            tfw.flush
            tfw.disconnect
            Result := on_save.item([once ""])
            if not Result.is_empty then
               filesystem.copy_to(backup, filename)
            end
         else
            Result := on_save.item([once "could not write to file #(1)" # filename])
         end
      end

   is_open: BOOLEAN
      do
         Result := filename /= Void
      end

   close
      do
         filename := Void
      end

feature {}
   make (a_filename: ABSTRACT_STRING)
      require
         a_filename /= Void
      do
         filename := a_filename.intern
      ensure
         is_open
      end

   filename: FIXED_STRING

   extern: EXTERN
   filesystem: FILESYSTEM

end -- class SIMPLE_FILE
