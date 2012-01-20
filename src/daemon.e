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
   LOGGING
   ARGUMENTS
   FILE_TOOLS

create {}
   main

feature {LOOP_ITEM}
   prepare (events: EVENTS_SET) is
      local
         t: TIME_EVENTS
      do
         if channel /= Void and then channel.is_connected then
            log.info.put_line(once "Awaiting connection.")
            events.expect(channel.event_can_read)
         else
            events.expect(t.timeout(0))
         end
      end

   is_ready (events: EVENTS_SET): BOOLEAN is
      do
         if events.event_occurred(channel.event_can_read) then
            channel.read_line
            Result := not channel.end_of_input and then not channel.last_string.is_empty
         end
         log.info.put_line(once "Connection received")
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
                  log.warning.put_line(once "Invalid master password -- vault not open")
               end
            when "list" then
               if command.count = 1 then
                  file := command.last
                  vault.list(file)
               else
                  log.warning.put_line(once "Invalid list file name")
               end
            when "menu" then
               if command.count >= 1 then
                  file := command.first
                  command.remove_first
                  vault.menu(file, channel.last_string.substring(5, channel.last_string.upper)) --| **** TODO: ugly, please read args from conf file
               else
                  log.warning.put_line(once "Invalid menu file name")
               end
            when "get" then
               if command.count = 2 then
                  file := command.first
                  name := command.last
                  vault.get(file, name)
               else
                  log.warning.put_line(once "Invalid get file name")
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
                  log.warning.put_line(once "Invalid set file name")
               end
            when "unset" then
               if command.count = 2 then
                  file := command.first
                  name := command.last
                  vault.unset(file, name)
               else
                  log.warning.put_line(once "Invalid unset file name")
               end
            when "save" then
               if command.count = 1 then
                  file := command.last
                  vault.save(file)
               else
                  log.warning.put_line(once "Invalid save file name")
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
                     log.warning.put_line(once "Invalid merge vault password")
                  end
                  merge_vault := Void
                  collect_garbage
               else
                  log.warning.put_line(once "Invalid merge file name")
               end
            when "close" then
               vault.close
               collect_garbage
            when "stop" then
               vault.close
               log.info.put_line(once "Terminating...")
               collect_garbage
               channel.disconnect
            else
               log.warning.put_line(once "Unknown command: #(1)" # command.first)
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
   processor: PROCESSOR

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
         log.info.put_line("Starting main loop.")
         loop_stack.run
         log.info.put_line("Terminated.")
         delete(fifo)
      end

   do_log (in_log: PROCEDURE[TUPLE]) is
      require
         in_log /= Void
      local
         logconf: LOG_CONFIGURATION
         conf: STRING_INPUT_STREAM
      do
         create conf.from_string(("[
               log configuration

               root DAEMON

               output
                  default is file "#(1)"
                  rotated each day keeping 3
                  end

               logger
                  DAEMON is
                  output default
                  level info
                  end

               end

               ]"
              # argument(3)
             ).out)
         logconf.load(conf, Void, Void, in_log)
      end

   run_in_child is
      do
         create vault.make(argument(2))
         start
      end

   run_in_parent (proc: PROCESS) is
      do
         log.info.put_line("Process id is #(1)" # &proc.id)
         die_with_code(0)
      end

   daemonize (detach: BOOLEAN) is
      local
         proc: PROCESS
      do
         if detach then
            proc := processor.fork
            if proc.is_child then
               do_log(agent run_in_child)
            else
               do_log(agent run_in_parent(proc))
            end
         else
            do_log(agent run_in_child)
         end
      rescue
         retry
      end

   main is
      local
         fifo_factory: FIFO; detach: BOOLEAN
      do
         if not argument_count.in_range(3, 4) then
            std_error.put_line(once "Usage: #(1) <fifo> <vault> <log> [-no_detach]" # command_name)
            die_with_code(1)
         end

         fifo := argument(1).intern
         fifo_factory.make(fifo)

         if not fifo_factory.exists(fifo) then
            log.error.put_line(once "Error while opening fifo #(1)" # fifo)
            die_with_code(1)
         end

         create command.with_capacity(16, 0)

         if argument_count = 3 then
            detach := True
         elseif argument(4).is_equal(once "-no_detach") then
            check not detach end
         else
            log.error.put_line(once "Unknown argument: #(1)" # argument(4))
            die_with_code(1)
         end

         daemonize(detach)
      end

invariant
   vault /= Void
   fifo /= Void
   channel /= Void
   command /= Void

end
