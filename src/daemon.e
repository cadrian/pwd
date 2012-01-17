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
class DAEMON

inherit
   JOB
      undefine
         default_create
      end

insert
   PROCESS_FACTORY
   ARGUMENTS
      undefine
         default_create
      end

create {}
   main

feature {LOOP_ITEM}
   prepare (events: EVENTS_SET) is
      local
         t: TIME_EVENTS
      do
         if channel /= Void and then channel.is_connected then
            events.expect(channel.event_can_read)
         else
            events.expect(t.timeout(0))
         end
      end

   is_ready (events: EVENTS_SET): BOOLEAN is
      do
         if events.event_occurred(channel.event_can_read) then
            channel.read_line
            Result := not channel.last_string.is_empty
         end
      end

   continue is
      local
         cmd, file, name: STRING
      do
         command.clear_count
         channel.last_string.split_in(command)
         if not command.is_empty then
            cmd := command.first
            command.remove_first
            inspect
               cmd
            when "master" then
               vault.close
               if command.count = 1 then
                  vault.open(command.last)
               end
               if not vault.is_open then
                  std_output.put_line(once "Invalid master password")
               end
            when "list" then
               if command.count = 1 then
                  if vault.is_open then
                     file := command.last
                     vault.list(file)
                  end
               else
                  std_output.put_line(once "Invalid list file name")
               end
            when "dmenu" then
               if command.count >= 1 then
                  file := command.first
                  command.remove_first
                  vault.dmenu(file, command)
               else
                  std_output.put_line(once "Invalid dmenu file name")
               end
            when "get" then
               if command.count = 2 then
                  if vault.is_open then
                     file := command.first
                     name := command.last
                     vault.get(file, name)
                  end
               else
                  std_output.put_line(once "Invalid get file name")
               end
            when "set" then
               if command.count >= 2 then
                  if vault.is_open then
                     file := command.first
                     command.remove_first
                     name := command.first
                     command.remove_first
                     if command.is_empty then
                        vault.set(file, name, Void)
                     else
                        vault.set(file, name, command.first)
                     end
                  end
               else
                  std_output.put_line(once "Invalid set file name")
               end
            when "save" then
               if command.count = 1 then
                  if vault.is_open then
                     file := command.last
                     vault.save(file)
                  end
               else
                  std_output.put_line(once "Invalid save file name")
               end
            when "close" then
               vault.close
            when "stop" then
               channel.disconnect
            else
               std_output.put_line(once "Unknown command: #(1)" # command.first)
            end
         end
      end

   done: BOOLEAN is
      do
         Result := channel = Void or else not channel.is_connected
      end

   restart is
      do
         create channel.connect_to(fifo)
      end

feature {}
   channel: TEXT_FILE_READ_WRITE
         -- there must be at least one writer for the fifo to be blocking in select(2)
         -- see http://stackoverflow.com/questions/580013/how-do-i-perform-a-non-blocking-fopen-on-a-named-pipe-mkfifo

   vault: VAULT
   fifo: FIXED_STRING

   command: RING_ARRAY[STRING]

   start is
         -- the main loop
      local
         loop_stack: LOOP_STACK
         ft: FILE_TOOLS
      do
         create loop_stack.make
         loop_stack.add_job(Current)
         restart
         loop_stack.run
         std_output.put_line("~~~~ DONE ~~~~")
         ft.delete(fifo)
      end

   create_fifo is
      local
         path: POINTER; sts: INTEGER
      do
         c_inline_h("#include <sys/types.h>%N")
         c_inline_h("#include <sys/stat.h>%N")
         c_inline_h("#include <fcntl.h>%N")
         c_inline_h("#include <unistd.h>%N")
         path := fifo.to_external
         c_inline_c("[
                     _sts = mknod((const char*)_path, S_IFIFO | 0600, 0);
                     if (_sts == -1)
                        _sts = errno;

                     ]")
         if sts /= 0 then
            std_error.put_line(once "#(1): error #(2) while creating #(3)" # command_name # sts.out # fifo)
            die_with_code(1)
         end
      end

   daemonize is
      local
         proc: PROCESS
      do
         proc := create_process
         proc.duplicate
         if proc.is_child then
            start
         else
            std_output.put_integer(proc.id)
            std_output.put_new_line
            die_with_code(0)
         end
      end

   main is
      do
         if argument_count /= 2 then
            std_error.put_line(once "Usage: #(1) <fifo> <vault>" # command_name)
            die_with_code(1)
         end

         default_create
         direct_input := True
         direct_output := True
         direct_error := True

         fifo := argument(1).intern
         create_fifo
         create vault.make(argument(2))
         create command.with_capacity(16, 0)

         daemonize
      end

invariant
   vault /= Void
   fifo /= Void
   channel /= Void
   command /= Void

end
