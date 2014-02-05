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
class COMMAND_REMOTE_SHOW

inherit
   COMMAND_REMOTE_ACTION

create {COMMAND_REMOTE}
   make

feature {COMMANDER}
   name: FIXED_STRING is
      once
         Result := "show".intern
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING] is
      do
         if command.count = 2 then
            Result := filter_completions(remote_map.new_iterator_on_keys, word)
         else
            Result := no_completion
         end
      end

feature {}
   run_remote (command: COLLECTION[STRING]; remote_name: FIXED_STRING; remote: REMOTE) is
      do
         if remote = Void then
            error_and_help(message_unknown_remote # remote_name, command)
         else
            io.put_new_line
            remote.write_to(io)
            io.put_new_line
         end
      end

feature {ANY}
   help (command: COLLECTION[STRING]): STRING is
      do
         Result := once "[
                          [33mremote show [remote][0m
                                             Show a remote definition.

                         ]"
      end

end
