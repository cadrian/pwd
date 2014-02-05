-- This file is part of pwdmgr.
-- Copyright (C) 2012-2014 Cyril Adrian <cyril.adrian@gmail.com>
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
class CONSOLE

inherit
   CLIENT
      export {COMMAND} -- commands need access to a lot of client stuff
         copy_to_clipboard, read_password, call_server, send_save, tmpdir, master_pass
      redefine
         make, cleanup
      end

insert
   COMMANDER
   COMPLETION_TOOLS

create {}
   make

feature {} -- the CLIENT interface
   stop: BOOLEAN

   run is
      do
         fill_remote_map
         load_history

         from
            stop := False
            io.put_string(once "[
                                [1;32mWelcome to the pwdmgr administration console![0m

                                [32mpwdmgr Copyright (C) 2012-2014 Cyril Adrian <cyril.adrian@gmail.com>
                                This program comes with ABSOLUTELY NO WARRANTY; for details type [33mshow w[32m.
                                This is free software, and you are welcome to redistribute it
                                under certain conditions; type [33mshow c[32m for details.[0m

                                Type [33mhelp[0m for details on available options.
                                Just hit [33m<enter>[0m to exit.

                                ]")
         until
            stop
         loop
            read_command
            if command_line.is_empty then
               stop := True
            else
               run_command
            end
         end
      rescue
         if exceptions.is_signal then
            log.info.put_line(once "Killed by signal #(1), exitting gracefully." # exceptions.signal_number.out)
            cleanup
            io.put_new_line
            die_with_code(0)
         end
      end

   cleanup is
      do
         Precursor
         save_history
      end

feature {} -- readline history management
   history_size: INTEGER

   load_history is
      local
         histsize: FIXED_STRING
      do
         histsize := conf(config_history_size)
         if histsize = Void or else not histsize.is_integer then
            history_size := 0
         else
            history_size := histsize.to_integer
         end
         rio.history.from_file(history_filename)
      end

   save_history is
      do
         rio.history.write(history_filename)
         if history_size > 0 then
            rio.history.truncate_file(history_filename, history_size)
         end
      end

   history_filename: FIXED_STRING is
      local
         xdg: XDG
      once
         Result := ("#(1)/.console_history" # xdg.data_home).intern
      end

feature {} -- command management
   command_line: RING_ARRAY[STRING] is
      once
         create Result.with_capacity(16, 0)
      end

   rio: READLINE_INPUT_STREAM is
      once
         create Result.make
         Result.set_prompt("> ")
      end

   read_command is
      do
         rio.read_line
         command_line.clear_count
         rio.last_string.split_in(command_line)
      end

   run_command is
      require
         not command_line.is_empty
         channel.is_ready
      local
         cmd: STRING; command: COMMAND
      do
         cmd := command_line.first
         command := commands.fast_reference_at(cmd.intern)
         if command /= Void then
            command_line.remove_first
            command.run(command_line)
         else
            run_get
         end
      ensure
         channel.is_ready
      end

feature {} -- local vault commands
   unknown_key (key: ABSTRACT_STRING) is
      do
         io.put_line(once "[1mUnknown password:[0m #(1)" # key)
      end

   run_get is
      do
         do_get(command_line.first, agent copy_to_clipboard(?), agent unknown_key(?))
      end

feature {COMMAND}
   do_stop is
      do
         call_server(create {QUERY_STOP}.make, agent when_stop(?))
         stop := True
      end

feature {}
   when_stop (a_reply: MESSAGE) is
      local
         reply: REPLY_STOP
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if not reply.error.is_empty then
               log.error.put_line(reply.error)
            end
         else
            log.error.put_line(once "Unexpected reply")
         end
      end

feature {COMMAND} -- command helpers
   on_cancel: PROCEDURE[TUPLE] is
         -- an agent called on cancel
      once
         Result := agent is
                   do
                      std_output.put_line(once "[1mCancelled.[0m")
                   end
      end

   less (string: ABSTRACT_STRING) is
         -- invoke less with the `string' to be displayed
      local
         proc: PROCESS
      do
         proc := processor.execute(once "less", once "-R")
         if proc.is_connected then
            proc.input.put_string(string)
            proc.input.flush
            proc.input.disconnect
            proc.wait
         end
      end

   list_remotes: STRING is
         -- a formatted list of all the known remotes
      local
         i: INTEGER
      do
         Result := once ""
         Result.clear_count
         from
            i := remote_map.lower
         until
            i > remote_map.upper
         loop
            if i > remote_map.lower then
               Result.append(once ", ")
            end
            Result.append(remote_map.key(i))
            i := i + 1
         end
      end

feature {} -- helpers
   remote_map: LINKED_HASHED_DICTIONARY[REMOTE, FIXED_STRING]

   fill_remote_map is
      local
         config_dir: DIRECTORY
         xdg: XDG
      do
         remote_map.clear_count

         create config_dir.scan(xdg.config_home)
         config_dir.new_iterator.do_all(agent load_remote(?))
      end

   load_remote (name: FIXED_STRING) is
      require
         name /= Void
      local
         remote_name: FIXED_STRING
      do
         if name.has_suffix(once ".rc") and then not name.same_as(once "config.rc") then
            remote_name := name.substring(name.lower, name.upper - 3)
            add_remote(remote_name)
         end
      end

   add_remote (name: FIXED_STRING) is
      require
         name /= Void
      local
         remote: REMOTE
         remote_factory: REMOTE_FACTORY
      do
         if not name.is_empty then
            remote := remote_factory.load_remote(name, Current)
            if remote /= Void then
               log.info.put_line(once "Adding remote: #(1)" # name)
               remote_map.add(remote, name)
            else
               log.warning.put_line(once "Invalid remote #(1) -- not added" # name)
            end
         end
      end

   config_history_size: FIXED_STRING is
      once
         Result := "history.size".intern
      end

   dont_complete (word: FIXED_STRING): AVL_SET[FIXED_STRING] is
      require
         not command_line.is_empty
      do
         log.trace.put_line(once "dont_complete #(1)" # command_line.first)
         create Result.make
      end

   make is
      local
         commands_map: LINKED_HASHED_DICTIONARY[COMMAND, FIXED_STRING]
         command: COMMAND
      do
         create remote_map.make

         create commands_map.make
         create {COMMAND_ADD   } command.make(Current, commands_map)
         create {COMMAND_HELP  } command.make(Current, commands_map)
         create {COMMAND_LIST  } command.make(Current, commands_map)
         create {COMMAND_LOAD  } command.make(Current, commands_map, remote_map)
         create {COMMAND_MASTER} command.make(Current, commands_map)
         create {COMMAND_MERGE } command.make(Current, commands_map, remote_map)
         create {COMMAND_REM   } command.make(Current, commands_map)
         create {COMMAND_REMOTE} command.make(Current, commands_map, remote_map)
         create {COMMAND_SAVE  } command.make(Current, commands_map, remote_map)
         create {COMMAND_SHOW  } command.make(Current, commands_map)
         create {COMMAND_STOP  } command.make(Current, commands_map)

         commands := commands_map

         rio.completion.set_completion_agent(agent complete(?, ?, ?))
         Precursor
      end

   complete (word: FIXED_STRING; start_index, end_index: INTEGER): TRAVERSABLE[FIXED_STRING] is
      require
         word /= Void
      local
         command: COMMAND
         buffer: FIXED_STRING
      do
         if start_index = 0 then
            Result := filter_completions(commands.new_iterator_on_keys, word)
         else
            buffer := rio.buffer
            if end_index /= buffer.count then
               Result := no_completion
            else
               command_line.clear_count
               buffer.substring(buffer.lower, buffer.lower + start_index - 1).split_in(command_line)
               command := commands.fast_reference_at(command_line.first.intern)
               if command /= Void then
                  log.trace.put_line(once "Completion of command: #(1) for word #(2)" # command_line.out # word)
                  Result := command.complete(command_line, word)
               else
                  Result := no_completion
               end
            end
         end
      end

invariant
   remote_map /= Void

end
