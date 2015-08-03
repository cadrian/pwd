-- This file is part of pwd.
-- Copyright (C) 2012-2014 Cyril Adrian <cyril.adrian@gmail.com>
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
class VAULT

insert
   LOGGING
   FILE_TOOLS
   SYSTEM
   CONFIGURABLE

create {ANY}
   make

feature {ANY}
   is_open: BOOLEAN

feature {ANY}
   close
      require
         is_open
      do
         if dirty then
            log.warning.put_line("**** CLOSING DIRTY VAULT!")
         end
         data.for_each(agent (key: KEY)
            do
               key.clear
            end(?))
         data.clear_count
         set_environment_variable(once "VAULT_MASTER", once "")
         is_open := False
         log.info.put_line(once "Vault closed: #(1)" # file)
      ensure
         not is_open
      end

   open (master: STRING)
      require
         master /= Void
         not is_open
      local
         proc: PROCESS; vault_file: TEXT_FILE_READ
      do
         set_environment_variable(once "VAULT_MASTER", master)
         create vault_file.connect_to(file)
         if vault_file.is_connected then
            log.trace.put_line(once "open vault")
            proc := processor.execute_redirect(once "openssl", once "#(1) -d -a -pass env:VAULT_MASTER" # conf(config_openssl_cipher))
            if proc.is_connected then
               extern.splice(vault_file, proc.input)
               proc.input.disconnect
               read_data(proc.output)
               proc.wait
               if proc.status = 0 then
                  is_open := True
               else
                  set_environment_variable(once "VAULT_MASTER", once "")
               end
            end

            vault_file.disconnect
         else
            log.trace.put_line(once "open vault as new")
            dirty := True
            is_open := True
         end

         if is_open then
            log.info.put_line(once "Vault open: #(1)" # file)
         else
            log.error.put_line(once "VAULT NOT OPEN! #(1)" # file)
         end
      end

   pass (key_name: STRING): STRING
      require
         is_open
         key_name /= Void
      local
         key: KEY
      do
         key := data.reference_at(key_name.intern)
         if key /= Void then
            Result := key.pass
         end
      end

   count: INTEGER
      do
         Result := data.count
      end

   for_each_key (action: PROCEDURE[TUPLE[FIXED_STRING]])
      require
         is_open
         action /= Void
      do
         data.for_each(agent (a: PROCEDURE[TUPLE[FIXED_STRING]]; k: KEY; n: FIXED_STRING)
            do
               if not k.is_deleted then
                  a.call([n])
               end
            end(action, ?, ?))
      end

   merge (other: like Current): ABSTRACT_STRING
      require
         is_open
         other.is_open
      do
         data.for_each_item(agent merge_other(other.data, ?))
         other.data.for_each_item(agent add_key(?))
         dirty := True
         Result := once ""
      end

   save: ABSTRACT_STRING
      require
         is_open
      local
         proc: PROCESS; tfw: TEXT_FILE_WRITE; ft: FILE_TOOLS; backup: STRING
      do
         Result := once ""
         if dirty then
            backup := once ""
            backup.make_from_string(file)
            backup.extend('~')
            ft.copy_to(file, backup)
            proc := processor.execute_redirect(once "openssl", once "#(1) -a -pass env:VAULT_MASTER" # conf(config_openssl_cipher))
            if proc.is_connected then
               print_all_keys(proc.input)
               proc.input.flush
               proc.input.disconnect

               create tfw.connect_to(file)
               if tfw.is_connected then
                  extern.splice(proc.output, tfw)
                  tfw.flush
                  tfw.disconnect
                  dirty := False
               else
                  Result := once "could not write to file #(1)" # file
               end

               proc.wait
               if proc.status /= 0 then
                  ft.copy_to(backup, file)
                  Result := once "openssl returned status #(1)" # proc.status.out
               end
            end
         end
      ensure
         Result /= Void
         Result.is_empty = not dirty
      end

   set_random (a_name, a_recipe: STRING): ABSTRACT_STRING
      require
         is_open
         a_name /= Void
         a_recipe /= Void
      local
         pass_: STRING
      do
         pass_ := generate_pass(a_recipe)
         if pass_ = Void then
            Result := once "Invalid recipe"
         else
            Result := set(a_name, pass_)
         end
      ensure
         Result /= Void
         Result.is_empty implies dirty
      end

   set (a_name, a_pass: STRING): ABSTRACT_STRING
      require
         is_open
         a_name /= Void
         a_pass /= Void
      local
         key: KEY
      do
         key := data.reference_at(a_name.intern)
         if key = Void then
            create key.new(a_name, a_pass)
            data.add(key, key.name)
         else
            key.set_pass(a_pass)
         end

         dirty := True
         Result := once ""
      ensure
         dirty
      end

   unset (a_name: STRING): ABSTRACT_STRING
      require
         is_open
         a_name /= Void
      local
         key: KEY
      do
         key := data.reference_at(a_name.intern)
         if key /= Void and then not key.is_deleted then
            key.delete
            dirty := True
         end

         Result := once ""
      end

feature {}
   merge_other (other: like data; key: KEY)
      local
         other_key: KEY
      do
         other_key := other.reference_at(key.name)
         if other_key /= Void then
            key.merge(other_key)
         end
      end

   add_key (key: KEY)
      do
         data.add(key, key.name)
      end

feature {}
   print_all_keys (stream: OUTPUT_STREAM)
      require
         stream.is_connected
      do
         data.for_each(agent print_key(?, ?, stream))
      end

   print_key (key: KEY; name: FIXED_STRING; stream: OUTPUT_STREAM)
      require
         stream.is_connected
      do
         stream.put_line(key.encoded)
      end

   read_data (a_data: INPUT_STREAM)
      require
         a_data.is_connected
         data.is_empty
      local
         line: STRING; key: KEY
      do
         log.trace.put_line(once "reading vault data...")
         from
            a_data.read_line
         until
            a_data.end_of_input
         loop
            line := a_data.last_string
            create key.decode(line)
            if key.is_valid then
               data.add(key, key.name)
            end

            a_data.read_line
         end

         log.trace.put_line(once "vault data read.")
      end

   generate_pass (recipe: ABSTRACT_STRING): STRING
      require
         recipe /= Void
      local
         g: PASS_GENERATOR
      do
         log.trace.put_line(once "generating random pass (may take time, depending on the system entropy)")
         create g.parse(recipe)
         if g.is_valid then
            Result := g.generated
         else
            log.warning.put_line(once "Invalid recipe: #(1)" # recipe)
         end
      end

feature {}
   make (a_file: ABSTRACT_STRING)
      require
         a_file /= Void
      do
         file := a_file.intern
         create data.make
      ensure
         file = a_file.intern
      end

   dirty: BOOLEAN

   extern: EXTERN

   processor: PROCESSOR

   config_openssl_cipher: FIXED_STRING
      once
         Result := ("openssl.cipher").intern
      end

feature {VAULT}
   data: AVL_DICTIONARY[KEY, FIXED_STRING]
   file: FIXED_STRING

invariant
   file /= Void
   data /= Void
   data.for_all(agent (key: KEY; name: FIXED_STRING): BOOLEAN
      do
         Result := key /= Void and then name = key.name and then key.is_valid
      end(?, ?))
   not is_open implies data.is_empty

end -- class VAULT
