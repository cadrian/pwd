-- This file is part of pwdmgr.
-- Copyright (C) 2012 Cyril Adrian <cyril.adrian@gmail.com>
--
-- pwdmgr is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, version 3 of the License.
--
-- pwdmgr is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with pwdmgr.  If not, see <http://www.gnu.org/licenses/>.
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
   open_new (pass: STRING) is
      require
         pass /= Void
         not is_open
      do
         log.info.put_line(once "open vault as new")
         set_environment_variable(once "VAULT_MASTER", pass)
         dirty := True
         is_open := True
      end

   open (pass: STRING) is
      require
         pass /= Void
         not is_open
      local
         proc: PROCESS; vault_file: TEXT_FILE_READ
      do
         log.info.put_line(once "open vault")
         create vault_file.connect_to(file)
         if vault_file.is_connected then
            set_environment_variable(once "VAULT_MASTER", pass)
            proc := processor.execute_redirect(once "openssl", once "#(1) -d -a -pass env:VAULT_MASTER" # conf(config_openssl_cipher))
            if proc.is_connected then
               fifo.splice(vault_file, proc.input)
               proc.input.disconnect
               read_data(proc.output)
               proc.wait
               is_open := proc.status = 0
            end
            vault_file.disconnect
         end
         if is_open then
            log.info.put_line(once "Vault open: #(1)" # file)
         else
            log.error.put_line(once "VAULT NOT OPEN! #(1)" # file)
         end
      end

   close is
      do
         if is_open then
            data.clear_count
            set_environment_variable(once "VAULT_MASTER", once "")
            is_open := False
            log.info.put_line(once "Vault closed: #(1)" # file)
         end
      ensure
         not is_open
      end

   is_open: BOOLEAN

   list (filename: STRING) is
      require
         filename /= Void
      do
         log.info.put_line(once "#(1): list" # filename)
         run_open(filename, agent do_list)
      end

   save (filename: STRING) is
      require
         filename /= Void
      do
         log.info.put_line(once "#(1): save" # filename)
         run_open(filename, agent do_save)
      end

   get (filename, name: STRING) is
      require
         filename /= Void
         name /= Void
      do
         log.info.put_line(once "#(1): get #(2)" # filename # name)
         run_open(filename, agent do_get(?, name))
      end

   set (filename, name, pass: STRING) is
      require
         filename /= Void
         name /= Void
      do
         if pass = Void then
            log.info.put_line(once "#(1): set #(2)" # filename # name)
         else
            log.info.put_line(once "#(1): set #(2) ****" # filename # name)
         end
         run_open(filename, agent do_set(?, name, pass))
      end

   unset (filename, name: STRING) is
      require
         filename /= Void
         name /= Void
      do
         log.info.put_line(once "#(1): unset #(2)" # filename # name)
         run_open(filename, agent do_unset(?, name))
      end

   merge (filename: STRING; other: like Current) is
         -- The greatest id is kept.
         -- If the ids are equal the local is kept.
      require
         filename /= Void
         other.is_open
      do
         log.info.put_line(once "#(1): merge vault #(2) + #(3)" # filename # file # other.file)
         run_open(filename, agent do_merge(?, other))
      end

   ping (filename: STRING) is
      require
         filename /= Void
      do
         log.info.put_line(once "#(1): ping" # filename)
         reply_pong(filename)
      end

feature {}
   do_list (stream: OUTPUT_STREAM) is
      require
         is_open
         stream.is_connected
      do
         print_all_names(stream)
      end

   do_save (stream: OUTPUT_STREAM) is
      require
         is_open
         stream.is_connected
      local
         proc: PROCESS
      do
         if dirty then
            proc := processor.execute_redirect(once "openssl", once "#(1) -a -pass env:VAULT_MASTER" # conf(config_openssl_cipher))
            if proc.is_connected then
               print_all_keys(proc.input)
               proc.input.flush
               proc.input.disconnect
               fifo.splice(proc.output, stream)
               proc.wait
            end
         end
      end

   do_get (stream:  OUTPUT_STREAM; name: STRING) is
      require
         is_open
         stream.is_connected
         name /= Void
      do
         display_name_and_pass(name.intern, stream)
      end

   do_set (stream: OUTPUT_STREAM; name, pass: STRING) is
      require
         is_open
         stream.is_connected
         name /= Void
      do
         set_key(name, pass, stream)
      end

   do_unset (stream: OUTPUT_STREAM; name: STRING) is
      require
         is_open
         stream.is_connected
         name /= Void
      do
         delete_key(name.intern, stream)
      end

   do_merge (stream: OUTPUT_STREAM; other: like Current) is
      require
         is_open
         stream.is_connected
         other.is_open
      do
         -- merge existing
         data.do_all(agent merge_other(other.data, ?))
         -- add missing
         other.data.do_all(agent add_key(?))
         stream.put_line(once "Merge done.")
         dirty := True
      end

feature {}
   reply_not_open (filename: STRING) is
      require
         filename /= Void
         not is_open
      local
         tfw: TEXT_FILE_WRITE
      do
         log.warning.put_line("#(1): command called on closed vault #(2)" # filename # file)
         create tfw.connect_to(filename)
         if tfw.is_connected then
            tfw.put_line(once "VAULT NOT OPEN")
            tfw.disconnect
         end
      end

   run_open (filename: STRING; if_open: PROCEDURE[TUPLE[OUTPUT_STREAM]]) is
      require
         filename /= Void
      local
         tfw: OUTPUT_STREAM
      do
         if is_open then
            create {TEXT_FILE_WRITE} tfw.connect_to(filename)
            if tfw.is_connected then
               log.trace.put_line(once "found fifo #(1)" # filename)
               if_open.call([tfw])
               tfw.disconnect
            else
               log.info.put_line(once "fifo #(1) not found!" # filename)
            end
         else
            reply_not_open(filename)
         end
      end

   reply_pong (filename: STRING) is
      require
         filename /= Void
      local
         tfw: TEXT_FILE_WRITE
      do
         create tfw.connect_to(filename)
         if tfw.is_connected then
            tfw.put_line(once "pong")
            tfw.disconnect
         end
      end

feature {}
   merge_other (other: like data; key: KEY) is
      local
         other_key: KEY
      do
         other_key := other.reference_at(key.name)
         if other_key /= Void then
            key.merge(other_key)
         end
      end

   add_key (key: KEY) is
      do
         data.add(key, key.name)
      end

feature {}
   set_key (name: ABSTRACT_STRING; pass: STRING; stream: OUTPUT_STREAM) is
      local
         actual_pass: STRING; key: KEY
      do
         if pass = Void then
            actual_pass := generate_pass(once "an+s+14ansanansaan")
         else
            actual_pass := pass
         end

         key := data.reference_at(name.intern)
         if key = Void then
            create key.new(name, actual_pass)
            data.add(key, key.name)
         else
            key.set_pass(actual_pass)
         end

         check
            key.pass = actual_pass
            not key.is_deleted
         end

         display_key(key, stream)
         dirty := True
      end

   print_all_names (stream: OUTPUT_STREAM) is
      require
         stream.is_connected
      do
         data.do_all(agent print_name(?, ?, stream))
      end

   print_name (key: KEY; name: FIXED_STRING; stream: OUTPUT_STREAM) is
      require
         stream.is_connected
      do
         stream.put_line(name)
      end

   print_all_keys (stream: OUTPUT_STREAM) is
      require
         stream.is_connected
      do
         data.do_all(agent print_key(?, ?, stream))
      end

   print_key (key: KEY; name: FIXED_STRING; stream: OUTPUT_STREAM) is
      require
         stream.is_connected
      do
         stream.put_line(key.encoded)
      end

   display_key (key: KEY; stream: OUTPUT_STREAM) is
      require
         not key.is_deleted
         stream.is_connected
      do
         stream.put_line(once "#(1) #(2)" # key.name # key.pass)
      end

   display_name_and_pass (name: FIXED_STRING; stream: OUTPUT_STREAM) is
      require
         name /= Void
         stream.is_connected
      local
         key: KEY
      do
         key := data.reference_at(name)
         if key /= Void and then not key.is_deleted then
            log.trace.put_line(once "found key '#(1)'" # name)
            display_key(key, stream)
         else
            log.info.put_line(once "key '#(1)' not fount" # name)
            stream.put_line(name)
         end
      end

   display_or_add_key (name: FIXED_STRING; stream: OUTPUT_STREAM) is
      require
         name /= Void
         stream.is_connected
      local
         key: KEY
      do
         key := data.reference_at(name)
         if key /= Void and then not key.is_deleted then
            display_key(key, stream)
         else
            set_key(name, Void, stream)
         end
      end

   delete_key (name: FIXED_STRING; stream: OUTPUT_STREAM) is
      require
         name /= Void
         stream.is_connected
      local
         key: KEY
      do
         key := data.reference_at(name)
         if key /= Void and then not key.is_deleted then
            key.delete
            stream.put_line(name)
         end
      end

   read_data (a_data: INPUT_STREAM) is
      require
         a_data.is_connected
         data.is_empty
      local
         line: STRING; key: KEY
      do
         log.info.put_line(once "reading vault data...")
         from
            a_data.read_line
         until
            a_data.end_of_input
         loop
            line := a_data.last_string
            create key.make(line)
            if key.is_valid then
               data.add(key, key.name)
            end
            a_data.read_line
         end
         log.info.put_line(once "vault data read.")
      end

   generate_pass (recipe: STRING): STRING is
      require
         recipe /= Void
      local
         g: PASS_GENERATOR
      do
         log.trace.put_line(once "generating random pass (may take time, depending on the system entropy)")

         Result := ""
         create g.parse(recipe)
         if g.is_valid then
            Result := g.generated
         else
            log.warning.put_line(once "Invalid recipe: #(1)" # recipe)
         end
      ensure
         Result /= Void
      end

feature {}
   make (a_file: ABSTRACT_STRING) is
      require
         a_file /= Void
      do
         file := a_file.intern
         create data.make
      ensure
         file = a_file.intern
      end

   dirty: BOOLEAN
   fifo: FIFO

   processor: PROCESSOR

   config_openssl_cipher: FIXED_STRING is
      once
         Result := "openssl.cipher".intern
      end

feature {VAULT}
   data: AVL_DICTIONARY[KEY, FIXED_STRING]
   file: FIXED_STRING

invariant
   file /= Void
   data /= Void

   data.for_all(agent (key: KEY; name: FIXED_STRING): BOOLEAN is do Result := key /= Void and then name = key.name and then key.is_valid end)

   not is_open implies data.is_empty

end
