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
class SERVER

inherit
   PERIODIC_JOB
      undefine default_create
      redefine prepare, is_ready
      end
   QUERY_VISITOR

insert
   GLOBALS
   FILE_TOOLS

create {}
   make

feature {LOOP_ITEM}
   prepare (events: EVENTS_SET)
      do
         channel.prepare(events)
         Precursor(events)
      end

   is_ready (events: EVENTS_SET): BOOLEAN
      do
         channel_ready := channel.is_ready(events)
         if channel_ready then
            timeout_ready := False
            Result := True
         else
            timeout_ready := Precursor(events)
            Result := timeout_ready
         end
      end

   continue
      do
         if channel_ready then
            log.trace.put_line("Channel event received")
            channel.continue
         elseif timeout_ready then
            if vault.is_open then
               log.trace.put_line("Idle time exhausted, closing")
               vault.close
            else
               log.trace.put_line("Vault is closed")
            end
            period := {REAL 86400.0} -- one day
         else
            log.trace.put_line("Spurious continue, ignored")
         end
      end

   done: BOOLEAN
      do
         Result := channel.done
      end

   restart
      do
         channel.restart
      end

   collect_garbage
      local
         mem: MEMORY
      do
         mem.full_collect
      end

feature {}
   channel_ready, timeout_ready: BOOLEAN

   processor: PROCESSOR

   exceptions: EXCEPTIONS

   channel: SERVER_CHANNEL

   vault: VAULT

   is_running: BOOLEAN

   run_in_child
         -- the main loop
      local
         loop_stack: LOOP_STACK; tfw: TEXT_FILE_WRITE; pid: INTEGER; is_killed, initialized: BOOLEAN
      do
         if not is_killed then
            period := {REAL 86400.0} -- one day

            if initialized then
               log.info.put_line(once "Resuming main loop.")
            else
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
               channel.on_receive(agent run_message({MESSAGE}))
               channel.on_new_job(agent loop_stack.add_job({JOB}))
               loop_stack.add_job(Current)
               restart
               initialized := True
               log.info.put_line(once "Starting main loop.")
            end
            is_running := True
            loop_stack.run
            is_running := False
         end
         if vault.is_open then
            vault.close
         end

         channel.cleanup

         log.info.put_line(once "Terminated.")
      rescue
         if exceptions.is_signal then
            if exceptions.signal_number = 1 then
               log.info.put_line(once "Received SIGHUP, ignored.")
            else
               log.info.put_line(once "Killed by signal #(1), exitting gracefully." # exceptions.signal_number.out)
               is_killed := True
            end
            retry
         else
            log.info.put_line(once "Killed by exception #(1)." # exceptions.exception_name)
         end
      end

   run_in_parent (proc: PROCESS)
      do
         log.info.put_line("Process id is #(1)" # proc.id.out)
         die_with_code(0)
      end

   run_message (message: MESSAGE): MESSAGE
      require
         message /= Void
      do
         check
            reply = Void
         end
         message.accept(Current)
         Result := reply
         reply := Void
      end

   reply: MESSAGE

   preload
      do
         inspect
            configuration.argument_count
         when 0 then
            detach := True
         when 1 then
            if configuration.argument(1).is_equal("-no_detach") then
               check
                  not detach
               end
            else
               detach := True
               configuration.parse_extra_conf(configuration.argument(1))
            end
         when 2 then
            if configuration.argument(1).is_equal("-no_detach") then
               check
                  not detach
               end
               configuration.parse_extra_conf(configuration.argument(2))
            elseif configuration.argument(2).is_equal("-no_detach") then
               check
                  not detach
               end
               configuration.parse_extra_conf(configuration.argument(1))
            else
               std_error.put_line("One argument must be %"-no_detach%" and the other, the extra configuration file")
               die_with_code(1)
            end
         else
            std_error.put_line("Usage: #(1) [<fallback conf>] [-no_detach]" # command_name)
            die_with_code(1)
         end
         if configuration.main_config = Void then
            std_error.put_line("Could not find any valid configuration file")
            die_with_code(1)
         end
      end

   main
      local
         proc: PROCESS; channel_factory: CHANNEL_FACTORY
      do
         channel := channel_factory.new_server_channel
         if detach then
            proc := processor.fork
            if proc.is_child then
               run_in_child
            else
               run_in_parent(proc)
            end
         else
            log.info.put_line(once "Running not detached.")
            run_in_child
         end
      end

   detach: BOOLEAN

feature {QUERY_CLOSE}
   visit_close (query: QUERY_CLOSE)
      do
         vault.close
         period := {REAL 86400.0} -- one day
         collect_garbage
         create {REPLY_CLOSE} reply.make(once "")
      end

feature {QUERY_GET}
   visit_get (query: QUERY_GET)
      local
         pass: STRING
      do
         if vault.is_open then
            pass := vault.pass(query.key)
            if pass /= Void then
               create {REPLY_GET} reply.make(once "", query.key, pass)
            else
               create {REPLY_GET} reply.make(once "Unknown key", query.key, once "")
            end
         else
            create {REPLY_GET} reply.make(once "Vault not open", query.key, once "")
         end
      end

feature {QUERY_IS_OPEN}
   visit_is_open (query: QUERY_IS_OPEN)
      do
         create {REPLY_IS_OPEN} reply.make(once "", vault.is_open)
      end

feature {QUERY_LIST}
   visit_list (query: QUERY_LIST)
      local
         names: FAST_ARRAY[FIXED_STRING]
      do
         if vault.is_open then
            create names.with_capacity(vault.count)
            vault.for_each_key(agent (key: FIXED_STRING; a: FAST_ARRAY[FIXED_STRING])
               do
                  if not key.is_empty and then key.first /= '_' then
                     a.add_last(key)
                  end
               end(?, names))
            create {REPLY_LIST} reply.make(once "", names)
         else
            create {REPLY_LIST} reply.make(once "Vault not open", create {FAST_ARRAY[FIXED_STRING]}.make(0))
         end
      end

feature {QUERY_MASTER}
   visit_master (query: QUERY_MASTER)
      do
         if vault.is_open then
            vault.close
         end
         vault.open(query.master)
         if vault.is_open then
            period := {REAL 14400.0} -- 4 hours idle time
            create {REPLY_MASTER} reply.make(once "")
         else
            period := {REAL 86400.0} -- one day
            create {REPLY_MASTER} reply.make(once "Vault not open")
         end
      end

feature {QUERY_MERGE}
   visit_merge (query: QUERY_MERGE)
      local
         other: VAULT; error: ABSTRACT_STRING
      do
         if vault.is_open then
            create other.make(query.vault)
            other.open(query.master)
            if other.is_open then
               error := vault.merge(other)
               other.close
               create {REPLY_MERGE} reply.make(error, query.vault)
            else
               create {REPLY_MERGE} reply.make(once "Merge vault not open", query.vault)
            end
         else
            create {REPLY_MERGE} reply.make(once "Vault not open", query.vault)
         end
      end

feature {QUERY_PING}
   visit_ping (query: QUERY_PING)
      do
         create {REPLY_PING} reply.make(once "", query.id)
      end

feature {QUERY_SAVE}
   visit_save (query: QUERY_SAVE)
      local
         error: ABSTRACT_STRING
      do
         if vault.is_open then
            error := vault.save
            create {REPLY_SAVE} reply.make(error)
         else
            create {REPLY_SAVE} reply.make(once "Vault not open")
         end
      end

feature {QUERY_SET}
   visit_set (query: QUERY_SET)
      local
         error: ABSTRACT_STRING; pass: STRING
      do
         if vault.is_open then
            if query.recipe /= Void then
               error := vault.set_random(query.key, query.recipe)
            else
               error := vault.set(query.key, query.pass)
            end
            pass := vault.pass(query.key)
            create {REPLY_SET} reply.make(error, query.key, pass)
         else
            create {REPLY_SET} reply.make(once "Vault not open", query.key, once "")
         end
      end

feature {QUERY_STOP}
   visit_stop (query: QUERY_STOP)
      do
         if vault.is_open then
            vault.close
         end
         log.info.put_line(once "Terminating...")
         collect_garbage
         channel.disconnect
         create {REPLY_STOP} reply.make(once "")
      end

feature {QUERY_UNSET}
   visit_unset (query: QUERY_UNSET)
      local
         error: ABSTRACT_STRING
      do
         if vault.is_open then
            error := vault.unset(query.key)
            create {REPLY_UNSET} reply.make(error, query.key)
         else
            create {REPLY_UNSET} reply.make(once "Vault not open", query.key)
         end
      end

feature {QUERY_VERSION}
   visit_version (query: QUERY_VERSION)
      do
         create {REPLY_VERSION} reply.make(once "", version)
      end

invariant
   is_running implies vault /= Void
   is_running implies channel /= Void

end -- class SERVER
