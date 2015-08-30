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
class COMMAND_REMOTE_DELETE

inherit
   COMMAND_REMOTE_ACTION

create {COMMAND_REMOTE}
   make

feature {COMMANDER}
   name: FIXED_STRING
      once
         Result := ("delete").intern
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING]
      do
         if command.count = 2 then
            Result := filter_completions(remote_map.new_iterator_on_keys, word)
         else
            Result := no_completion
         end
      end

feature {}
   run_remote (command: COLLECTION[STRING]; remote_name: FIXED_STRING; remote: REMOTE)
      do
         if remote = Void then
            error_and_help(message_unknown_remote # remote_name, command)
         else
            remote.delete_file
            remote_map.fast_remove(remote.name)
         end
      end

feature {ANY}
   help (command: COLLECTION[STRING]): STRING
      do
         Result := once "[
                          [33mremote delete [remote][0m
                                             Delete a remote.
                                             [33m[remote][0m: see note below

                         ]"
      end

end -- class COMMAND_REMOTE_DELETE
