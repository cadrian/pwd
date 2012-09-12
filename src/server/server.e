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
class SERVER

inherit
   JOB
      undefine
         default_create
      end

insert
   GLOBALS
   FILE_TOOLS

create {}
   make

feature {LOOP_ITEM}
   prepare (events: EVENTS_SET) is
      do
         channel.prepare(events)
      end

   is_ready (events: EVENTS_SET): BOOLEAN is
      do
         Result := channel.is_ready(events)
      end

   continue is
      do
         channel.continue
      end

   done: BOOLEAN is
      do
         Result := channel.done
      end

   restart is
      do
         channel.restart
      end

   collect_garbage is
      local
         mem: MEMORY
      do
         mem.full_collect
      end

feature {}
   processor: PROCESSOR
   exceptions: EXCEPTIONS
   channel: SERVER_CHANNEL
   vault: VAULT
   is_running: BOOLEAN

   run_in_child is
         -- the main loop
      local
         loop_stack: LOOP_STACK
         tfw: TEXT_FILE_WRITE
         pid: INTEGER
         is_killed: BOOLEAN
      do
         if not is_killed then
            pid := processor.pid
            log.info.put_line(once "Starting server (#(1))." # pid.out)

            create tfw.connect_to(shared.server_pidfile)
            if tfw.is_connected then
               tfw.put_integer(pid)
               tfw.put_new_line
               tfw.disconnect
            end

            create vault.make(shared.vault_file)
            create loop_stack.make
            channel.on_receive(agent run_command)
            channel.on_new_job(agent loop_stack.add_job)
            loop_stack.add_job(Current)
            restart
            log.info.put_line(once "Starting main loop.")

            is_running := True
            loop_stack.run
            is_running := False
         end

         if vault.is_open then
            vault.close
         end
         channel.cleanup
      rescue
         if exceptions.is_signal then
            log.info.put_line(once "Killed by signal #(1), exitting gracefully." # exceptions.signal_number.out)
            is_killed := True
            retry
         else
            log.info.put_line(once "Killed by exception #(1)." # exceptions.exception_name)
         end
      end

   run_in_parent (proc: PROCESS) is
      do
         log.info.put_line("Process id is #(1)" # proc.id.out)
         die_with_code(0)
      end

   run_command (command: RING_ARRAY[STRING]) is
      require
         not command.is_empty
      local
         cmd, file, name, setcmd: STRING; merge_vault: VAULT
      do
         cmd := command.first
         command.remove_first
         inspect
            cmd

         when "ping" then
            file := command.last
            vault.ping(file)

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
                  vault.set_random(file, name, shared.default_recipe)
               else
                  setcmd := command.first
                  command.remove_first
                  inspect
                     setcmd
                  when "random" then
                     if command.is_empty then
                        vault.set_random(file, name, shared.default_recipe)
                     else
                        vault.set_random(file, name, command.first)
                     end
                  when "given" then
                     if command.is_empty then
                        log.warning.put_line(once "Missing given password")
                     else
                        vault.set(file, name, command.first)
                     end
                  else
                     log.warning.put_line(once "Invalid set command")
                  end
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

   preload is
      do
         inspect
            configuration.argument_count
         when 0 then
            detach := True
         when 1 then
            if configuration.argument(1).is_equal(once "-no_detach") then
               check not detach end
            else
               detach := True
               configuration.parse_extra_conf(configuration.argument(1))
            end
         when 2 then
            if configuration.argument(1).is_equal(once "-no_detach") then
               check not detach end
               configuration.parse_extra_conf(configuration.argument(2))
            elseif configuration.argument(2).is_equal(once "-no_detach") then
               check not detach end
               configuration.parse_extra_conf(configuration.argument(1))
            else
               std_error.put_line("One argument must be %"-no_detach%" and the other, the extra configuration file")
               die_with_code(1)
            end
         else
            std_error.put_line(once "Usage: #(1) [<fallback conf>] [-no_detach]" # command_name)
            die_with_code(1)
         end

         if configuration.main_config = Void then
            std_error.put_line(once "Could not find any valid configuration file")
            die_with_code(1)
         end
      end

   main is
      local
         proc: PROCESS
         channel_factory: CHANNEL_FACTORY
      do
         channel := channel_factory.new_server_channel

         if detach then
            proc := processor.fork
            if proc.is_child then
               run_in_child
               log.info.put_line(once "Terminated.")
            else
               run_in_parent(proc)
            end
         else
            log.info.put_line(once "Running not detached.")
            run_in_child
            log.info.put_line(once "Terminated.")
         end
      end

   detach: BOOLEAN

invariant
   is_running implies vault /= Void
   is_running implies channel /= Void

end
