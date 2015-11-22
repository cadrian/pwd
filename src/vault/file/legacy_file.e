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
   KEY_HANDLER
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
         Result := once ""
      end

   read_data (keys: DICTIONARY[KEY, FIXED_STRING]; a_data: INPUT_STREAM)
      require
         a_data.is_connected
         keys.is_empty
      local
         i: INTEGER; line: STRING; key: KEY
      do
         log.trace.put_line(once "reading legacy vault data...")
         from
            a_data.read_line
         until
            a_data.end_of_input
         loop
            i := i + 1
            line := a_data.last_string
            key := decode(line)
            if key /= Void then
               keys.add(key, key.name)
            else
               log.warning.put_line("Invalid line #(1), skipped -- WILL BE LOST" # i.out)
            end

            a_data.read_line
         end

         log.trace.put_line(once "legacy vault data read.")
      end

   decode (a_line: STRING): KEY
      require
         a_line /= Void
      local
         dat, pass: STRING; name: FIXED_STRING; add_count, del_count: INTEGER
         bzero: BZERO
      do
         if decoder.match(a_line) then
            dat := once ""

            bzero(dat)
            decoder.append_named_group(a_line, dat, once "name")
            name := dat.intern

            bzero(dat)
            decoder.append_named_group(a_line, dat, once "add")
            add_count := dat.to_integer

            bzero(dat)
            decoder.append_named_group(a_line, dat, once "del")
            del_count := dat.to_integer

            bzero(dat)
            decoder.append_named_group(a_line, dat, once "pass")
            pass := dat.twin

            bzero(dat)

            create Result.from_file(name, pass, add_count, del_count)
         end

         bzero(a_line)
      end

   decoder: REGULAR_EXPRESSION
      local
         builder: REGULAR_EXPRESSION_BUILDER
      once
         Result := builder.convert_python_pattern("^(?P<name>[^:]+):(?P<add>[0-9]+):(?P<del>[0-9]+):(?P<pass>.*)$")
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
         stream.put_line(encoded(key))
      end

   pass_error (error: ABSTRACT_STRING): ABSTRACT_STRING then error end

   encoded (key: KEY): ABSTRACT_STRING
      do
         Result := encoder # key.name # key.add_count.out # key.del_count.out # key.pass
      end

   encoder: FIXED_STRING
      once
         Result := ("#(1):#(2):#(3):#(4)").intern
      end

end -- class LEGACY_FILE
