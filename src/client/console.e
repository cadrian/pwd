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
class CONSOLE

inherit
   CLIENT
      redefine
         make, cleanup
      end

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

                                [32mpwdmgr Copyright (C) 2012 Cyril Adrian <cyril.adrian@gmail.com>
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
            if command.is_empty then
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
   command: RING_ARRAY[STRING] is
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
         command.clear_count
         rio.last_string.split_in(command)
      end

   commands: MAP[COMMAND, FIXED_STRING]

   run_command is
      require
         not command.is_empty
         channel.is_ready
      local
         cmd: STRING; command_agents: TUPLE[PROCEDURE[TUPLE], FUNCTION[TUPLE[FIXED_STRING], AVL_SET[FIXED_STRING]]]
      do
         cmd := command.first
         command_agents := commands.fast_reference_at(cmd.intern)
         if command_agents /= Void then
            command.remove_first
            command_agents.first.call([])
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
         do_get(command.first, agent xclip, agent unknown_key)
      end

feature {COMMAND}
   do_stop is
      do
         stop := True
      end

feature {} -- help

   run_show is

feature {} -- remote vault management
   run_save is
         -- save to remote

   on_cancel: PROCEDURE[TUPLE] is
      once
         Result := agent is do std_output.put_line(once "[1mCancelled.[0m") end
      end

feature {} -- helpers
   merge_vault: FIXED_STRING is
      once
         Result := ("#(1)/merge_vault" # tmpdir).intern
      end

   less (string: ABSTRACT_STRING) is
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

   remote_map: LINKED_HASHED_DICTIONARY[REMOTE, FIXED_STRING]

   fill_remote_map is
      local
         config_dir: DIRECTORY
         xdg: XDG
      do
         remote_map.clear_count

         create config_dir.scan(xdg.config_home)
         config_dir.new_iterator.do_all(agent load_remote)
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
               remote_map.add(remote, name)
            end
         end
      end

   list_remotes: STRING is
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

   selected_remote: REMOTE is
      do
         if remote_map.is_empty then
            std_output.put_line(once "[1mNo remote defined![0m")
         else
            if remote_map.count = 1 then
               if not command.is_empty then
                  std_output.put_line(once "[1mRemote argument ignored (only one remote)[0m")
               end
               Result := remote_map.first
            else
               if command.is_empty then
                  std_output.put_line(once "[1mPlease specify the remote to use (#(1))[0m" # list_remotes)
               else
                  if command.count > 1 then
                     std_output.put_line(once "[1mAll arguments but the first one are ignored[0m")
                  end
                  Result := remote_map.fast_reference_at(command.first.intern)
                  if Result = Void then
                     std_output.put_line(once "[1mUnknown remote: #(1)[0m" # command.first)
                  end
               end
            end
         end
      end

   help_list_remotes: ABSTRACT_STRING is
      do
         if remote_map.is_empty then
            Result := once "There are no remotes defined."
         elseif remote_map.count = 1 then
            Result := once "There is only one remote defined: [1m#(1)[0m" # remote_map.key(remote_map.lower)
         else
            Result := once "The defined remotes are:%N                 [1;33m|[0m [1m#(1)[0m" # list_remotes
         end
      end

   config_history_size: FIXED_STRING is
      once
         Result := "history.size".intern
      end

   dont_complete (word: FIXED_STRING): AVL_SET[FIXED_STRING] is
      require
         not command.is_empty
      do
         log.trace.put_line(once "dont_complete #(1)" # command.first)
         create Result.make
      end

   make is
      local
         commands_map: LINKED_HASHED_DICTIONARY[COMMAND, FIXED_STRING]
      do
         create remote_map.make

         create commands_map.make(0)
         create {COMMAND_ADD   }.make(Current, commands_map)
         create {COMMAND_HELP  }.make(Current, commands_map)
         create {COMMAND_LIST  }.make(Current, commands_map)
         create {COMMAND_LOAD  }.make(Current, commands_map)
         create {COMMAND_MASTER}.make(Current, commands_map)
         create {COMMAND_MERGE }.make(Current, commands_map)
         create {COMMAND_REM   }.make(Current, commands_map)
         create {COMMAND_REMOTE}.make(Current, commands_map)
         create {COMMAND_SAVE  }.make(Current, commands_map)
         create {COMMAND_SHOW  }.make(Current, commands_map)
         create {COMMAND_STOP  }.make(Current, commands_map)

         commands := commands_map

         rio.completion.set_completion_agent(agent complete)
         Precursor
      end

   complete (word: FIXED_STRING; start_index, end_index: INTEGER): TRAVERSABLE[FIXED_STRING] is
      require
         word /= Void
      local
         command_agents: TUPLE[PROCEDURE[TUPLE], FUNCTION[TUPLE[FIXED_STRING], AVL_SET[FIXED_STRING]]]
         buffer: FIXED_STRING
      do
         if start_index = 0 then
            Result := complete_first_word(word)
         else
            buffer := rio.buffer
            command.clear_count
            buffer.substring(buffer.lower, start_index + buffer.lower).split_in(command)
            command_agents := commands.fast_reference_at(command.first.intern)
            if command_agents /= Void and then command_agents.second /= Void then
               Result := command_agents.second.item([word])
            end
         end
      end

   complete_first_word (word: FIXED_STRING): AVL_SET[FIXED_STRING] is
      do
         create Result.make
         commands.new_iterator_on_keys.do_all(agent (word, entry: FIXED_STRING; completions: AVL_SET[FIXED_STRING]) is
                                              do
                                                 if entry.has_prefix(word) then
                                                    completions.fast_add(entry)
                                                 end
                                              end
         -- TODO: add known keys (ask the server)
      end

invariant
   remote_map /= Void
   commands /= Void

end
