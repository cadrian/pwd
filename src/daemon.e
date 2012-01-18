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
   FILE_TOOLS
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
         cmd, file, name: STRING; merge_vault: VAULT
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
                  io.put_line(once "Invalid master password")
               end
            when "list" then
               if command.count = 1 then
                  file := command.last
                  vault.list(file)
               else
                  io.put_line(once "Invalid list file name")
               end
            when "menu" then
               if command.count >= 1 then
                  file := command.first
                  command.remove_first
                  vault.menu(file, command)
               else
                  io.put_line(once "Invalid menu file name")
               end
            when "get" then
               if command.count = 2 then
                  file := command.first
                  name := command.last
                  vault.get(file, name)
               else
                  io.put_line(once "Invalid get file name")
               end
            when "set" then
               if command.count >= 2 then
                  file := command.first
                  command.remove_first
                  name := command.first
                  command.remove_first
                  if command.is_empty then
                     vault.set(file, name, Void)
                  else
                     vault.set(file, name, command.first)
                  end
               else
                  io.put_line(once "Invalid set file name")
               end
            when "unset" then
               if command.count = 2 then
                  file := command.first
                  name := command.last
                  vault.unset(file, name)
               else
                  io.put_line(once "Invalid unset file name")
               end
            when "save" then
               if command.count = 1 then
                  file := command.last
                  vault.save(file)
               else
                  io.put_line(once "Invalid save file name")
               end
            when "merge" then
               if command.count = 3 then
                  file := command.first
                  command.remove_first
                  create merge_vault.make(command.first)
                  merge_vault.open(command.last)
                  if merge_vault.is_open then
                     vault.merge(file, merge_vault)
                     merge_vault.close
                  else
                     io.put_line(once "Invalid merge vault password")
                  end
                  merge_vault := Void
                  collect_garbage
               else
                  io.put_line(once "Invalid merge file name")
               end
            when "close" then
               vault.close
               collect_garbage
            when "stop" then
               vault.close
               collect_garbage
               channel.disconnect
            else
               io.put_line(once "Unknown command: #(1)" # command.first)
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

   collect_garbage is
      local
         mem: MEMORY
      do
         mem.full_collect
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
      do
         create loop_stack.make
         loop_stack.add_job(Current)
         restart
         loop_stack.run
         io.put_line("~~~~ DONE ~~~~")
         delete(fifo)
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
            io.put_integer(proc.id)
            io.put_new_line
            die_with_code(0)
         end
      end

   main is
      local
         fifo_factory: FIFO
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
         fifo_factory.make(fifo)
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
