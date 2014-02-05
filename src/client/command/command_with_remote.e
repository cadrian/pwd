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
deferred class COMMAND_WITH_REMOTE
   -- a command that needs a remote as argument

inherit
   COMMAND
      rename
         make as make_command
      end

feature {COMMANDER}
   run (command: COLLECTION[STRING]) is
      local
         remote: REMOTE
      do
         remote := selected_remote(command)
         if remote /= Void then
            std_output.put_line(once "[32mPlease wait...[0m")
            run_remote(remote)
         end
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING] is
      do
         if command.count = 1 then
            Result := filter_completions(remote_map.new_iterator_on_keys, word)
         end
      end

feature {}
   run_remote (remote: REMOTE) is
      require
         remote /= Void
      deferred
      end

   make (a_client: like client; map: DICTIONARY[COMMAND, FIXED_STRING]; a_remote_map: like remote_map) is
      require
         a_client /= Void
         map /= Void
         not map.fast_has(name)
         a_remote_map /= Void
      do
         remote_map := a_remote_map
         make_command(a_client, map)
      ensure
         remote_map = a_remote_map
         client = a_client
         map.fast_at(name) = Current
      end

   remote_map: MAP[REMOTE, FIXED_STRING]

   selected_remote (command: COLLECTION[STRING]): REMOTE is
      require
         command /= Void
      do
         if remote_map.is_empty then
            error_and_help(once "No remote defined", command)
         else
            if remote_map.count = 1 then
               if command.count > 1 or else command.first.intern /= remote_map.first.name then
                  error_and_help(message_invalid_arguments, command)
               else
                  Result := remote_map.first
               end
            else
               if command.is_empty then
                  error_and_help(once "Please specify the remote to use (#(1))" # client.list_remotes, command)
               elseif command.count > 1 then
                  error_and_help(message_invalid_arguments, command)
               else
                  Result := remote_map.fast_reference_at(command.first.intern)
                  if Result = Void then
                     error_and_help(once "Unknown remote: #(1)" # command.first, command)
                  end
               end
            end
         end
      end

end
