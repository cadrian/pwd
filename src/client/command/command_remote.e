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
class COMMAND_REMOTE

inherit
   COMMAND
      rename make as make_command
      end

insert
   COMMANDER
   LOGGING

create {CONSOLE}
   make

feature {COMMANDER}
   name: FIXED_STRING
      once
         Result := ("remote").intern
      end

   run (command_line: COLLECTION[STRING])
      local
         subcmd: FIXED_STRING; command: COMMAND
      do
         if command_line.count < 1 then
            error_and_help(message_invalid_arguments, command_line)
         else
            subcmd := command_line.first.intern
            command := commands.fast_reference_at(subcmd)
            if command = Void then
               error_and_help(once "Unknown remote command: #(1)" # subcmd, command_line)
            else
               command_line.remove_first
               command.run(command_line)
            end
         end
      end

   complete (command_line: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING]
      local
         subcmd: FIXED_STRING; command: COMMAND
      do
         if command_line.count = 1 then
            Result := filter_completions(commands.new_iterator_on_keys, word)
         else
            subcmd := command_line.item(command_line.lower + 1).intern
            command := commands.fast_reference_at(subcmd)
            if command = Void then
               log.trace.put_line(once "Unknown remote command: #(1)" # subcmd)
               Result := no_completion
            else
               log.trace.put_line(once "Completing remote command: #(1)" # subcmd)
               Result := command.complete(command_line, word)
            end
         end
      end

   help (command_line: COLLECTION[STRING]): ABSTRACT_STRING
      local
         command: COMMAND; msg: STRING
      do
         if command_line /= Void and then not command_line.is_empty then
            command := commands.fast_reference_at(command_line.first.intern)
         end
         if command /= Void then
            Result := command.help(command_line)
         else
            msg := once ""
            msg.clear_count
            add_help(msg)
            msg.append(once "[

                             [1;33m|[0m [33m[remote][0m note:
                             [1;33m|[0m The [33mload[0m, [33msave[0m, [33mmerge[0m, and [33mremote[0m commands require
                             [1;33m|[0m an extra argument if there is more than one available
                             [1;33m|[0m remotes.
                             [1;33m|[0m In that case, the argument is the remote to select.
                             [1;33m|[0m
                             [1;33m|[0m #(1)

                             ]" # help_list_remotes)

            Result := msg
         end
      end

feature {}
   help_list_remotes: ABSTRACT_STRING
      do
         if remote_map.is_empty then
            Result := once "There are no remotes defined."
         elseif remote_map.count = 1 then
            Result := once "There is only one remote defined: [1m#(1)[0m" # remote_map.key(remote_map.lower)
         else
            Result := once "The defined remotes are:%N                 [1;33m|[0m [1m#(1)[0m" # client.list_remotes
         end
      end

   make (a_client: like client; map: DICTIONARY[COMMAND, FIXED_STRING]; a_remote_map: DICTIONARY[REMOTE, FIXED_STRING])
      local
         commands_map: LINKED_HASHED_DICTIONARY[COMMAND, FIXED_STRING]; command: COMMAND
      do
         create commands_map.make
         create {COMMAND_REMOTE_CREATE} command.make(a_client, commands_map, a_remote_map)
         create {COMMAND_REMOTE_DELETE} command.make(a_client, commands_map, a_remote_map)
         create {COMMAND_REMOTE_LIST} command.make(a_client, commands_map)
         create {COMMAND_REMOTE_PROXY} command.make(a_client, commands_map, a_remote_map)
         create {COMMAND_REMOTE_SET} command.make(a_client, commands_map, a_remote_map)
         create {COMMAND_REMOTE_SHOW} command.make(a_client, commands_map, a_remote_map)
         create {COMMAND_REMOTE_UNSET} command.make(a_client, commands_map, a_remote_map)

         commands := commands_map

         remote_map := a_remote_map

         make_command(a_client, map)
      end

   remote_map: MAP[REMOTE, FIXED_STRING]

end -- class COMMAND_REMOTE
