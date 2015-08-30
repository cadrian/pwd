-- This file is part of pwd.
-- Copyright (C) 2012-2015 Cyril Adrian <cyril.adrian@gmail.com>
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
deferred class COMMAND_REMOTE_ACTION
   -- a "remote" command action (i.e. sub-command)

inherit
   COMMAND
      rename make as make_command
      end

feature {COMMANDER}
   run (command_line: COLLECTION[STRING])
      local
         remote_name: FIXED_STRING; remote: REMOTE
      do
         if command_line.count < 1 then
            error_and_help(message_invalid_arguments, command_line)
         else
            remote_name := command_line.first.intern
            command_line.remove_first
            remote := remote_map.fast_reference_at(remote_name)
            run_remote(command_line, remote_name, remote)
         end
      end

feature {}
   run_remote (command: COLLECTION[STRING]; remote_name: FIXED_STRING; remote: REMOTE)
      require
         command /= Void
         remote_name /= Void
         remote /= Void implies remote.name = remote_name
      deferred
      end

   message_unknown_remote: STRING "Unknown remote: #(1)"

   message_property_failed: STRING "Failed (unknown property?)"

   make (a_client: like client; map: DICTIONARY[COMMAND, FIXED_STRING]; a_remote_map: like remote_map)
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

   remote_map: DICTIONARY[REMOTE, FIXED_STRING]

end -- class COMMAND_REMOTE_ACTION
