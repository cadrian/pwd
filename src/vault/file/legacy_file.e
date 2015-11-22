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
class LEGACY_FILE
   --
   -- Legacy vault file structure
   --

inherit
   VAULT_FILE

insert
   LOGGING

feature {ANY}
   load (keys: DICTIONARY[KEY, FIXED_STRING]; vault_io: VAULT_IO): ABSTRACT_STRING
      do
         Result := vault_io.load(agent on_open(keys, ?))
      end

   save (keys: DICTIONARY[KEY, FIXED_STRING]; vault_io: VAULT_IO): ABSTRACT_STRING
      do
         Result := vault_io.save(agent do_save(keys, ?), agent pass_error(?))
      end

feature {} -- load
   on_open (keys: DICTIONARY[KEY, FIXED_STRING]; vault_file: INPUT_STREAM): ABSTRACT_STRING
      do
         if vault_file /= Void then
            log.trace.put_line(once "open vault")
            read_data(keys, vault_file)
            vault_file.disconnect
         else
            log.trace.put_line(once "open vault as new")
         end
         Result := ""
      end

   read_data (keys: DICTIONARY[KEY, FIXED_STRING]; a_data: INPUT_STREAM)
      require
         a_data.is_connected
         keys.is_empty
      local
         line: STRING; key: KEY
      do
         log.trace.put_line(once "reading legacy vault data...")
         from
            a_data.read_line
         until
            a_data.end_of_input
         loop
            line := a_data.last_string
            create key.decode(line)
            if key.is_valid then
               keys.add(key, key.name)
            end

            a_data.read_line
         end

         log.trace.put_line(once "legacy vault data read.")
      end

feature {} -- save
   do_save (keys: DICTIONARY[KEY, FIXED_STRING]; stream: OUTPUT_STREAM): ABSTRACT_STRING
      do
         Result := once ""
         keys.for_each(agent print_key(?, ?, stream))
      end

   print_key (key: KEY; name: FIXED_STRING; stream: OUTPUT_STREAM)
      require
         stream.is_connected
      do
         stream.put_line(key.encoded)
      end

   pass_error (error: ABSTRACT_STRING): ABSTRACT_STRING then error end

end -- class LEGACY_FILE
