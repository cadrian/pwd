-- This file is part of pwdmgr.
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
            proc := processor.execute(once "openssl", once "bf -d -a -pass env:VAULT_MASTER")
            if proc.is_connected then
               fifo.splice(vault_file, proc.input)
               proc.input.disconnect
               read_data(proc.output)
               proc.wait
               is_open := proc.status = 0
            end
            vault_file.disconnect
         end
      end

   close is
      do
         if is_open then
            log.info.put_line(once "close vault")
            data.clear_count
            set_environment_variable(once "VAULT_MASTER", once "")
            is_open := False
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

   menu (filename, args: STRING) is
      do
         log.info.put_line(once "#(1): menu" # filename)
         run_open(filename, agent do_menu(?, args))
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
         log.info.put_line(once "#(1): set #(2)" # filename # name)
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
            proc := processor.execute(once "openssl", once "bf -a -pass env:VAULT_MASTER")
            if proc.is_connected then
               print_all_keys(proc.input)
               proc.input.flush
               proc.input.disconnect
               fifo.splice(proc.output, stream)
               proc.wait
            end
         end
      end

   do_menu (stream: OUTPUT_STREAM; args: STRING) is
      require
         is_open
         stream.is_connected
      local
         proc: PROCESS
      do
         --| **** TODO: it's stupid to let the client send arguments when read from the same configuration file
         proc := processor.execute(once "dmenu", args)
         if proc.is_connected then
            print_all_names(proc.input)
            proc.input.disconnect
            proc.output.read_line
            display_or_add_key(proc.output.last_string.intern, stream)
            proc.wait
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
               if_open.call([tfw])
               tfw.disconnect
            end
         else
            reply_not_open(filename)
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
            actual_pass := generate_pass
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
            display_key(key, stream)
         else
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

   generate_pass: STRING is
      local
         i: INTEGER; p: POINTER
      do
         Result := once ""
         Result.clear_count
         c_inline_c("_p = fopen(%"/dev/random%", %"rb%");%N")

         from
            extend_pass(p, letters, Result)
            extend_pass(p, symbols, Result)
            i := 2
         until
            i > 16
         loop
            extend_pass(p, pass_string, Result)
            i := i + 1
         end

         c_inline_c("fclose((FILE*)_p);%N")
      ensure
         Result /= Void
      end

   extend_pass (random: POINTER; range: FIXED_STRING; pass: STRING) is
      require
         not random.is_default
         range.count.in_range(1, 16383)
         pass /= Void
      local
         int: INTEGER_32
      do
         c_inline_c("_int=(((int)io_getc((FILE*)a1) & 0x7f) << 8) | (int)io_getc((FILE*)a1);%N") -- >>
         pass.extend(range.item(int \\ range.count + range.lower))
      ensure
         pass.count = old pass.count + 1
      end

   pass_string: FIXED_STRING is
      once
         Result := ("#(1)#(2)#(1)#(1)#(2)#(1)#(1)" # letters # symbols).intern
      end

   letters: FIXED_STRING is
      once
         Result := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".intern
      end

   symbols: FIXED_STRING is
      once
         Result := "(-_)~#{[|^@]}+=<>,?./!§".intern
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

feature {VAULT}
   data: AVL_DICTIONARY[KEY, FIXED_STRING]
   file: FIXED_STRING

invariant
   file /= Void
   data /= Void

   data.for_all(agent (key: KEY; name: FIXED_STRING): BOOLEAN is do Result := key /= Void and then name = key.name and then key.is_valid end)

   not is_open implies data.is_empty

end
