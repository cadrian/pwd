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
class COMMAND_REMOTE_LIST

inherit
   COMMAND

create {COMMAND_REMOTE}
   make

feature {COMMANDER}
   name: FIXED_STRING
      once
         Result := ("list").intern
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING]
      do
         Result := no_completion
      end

   run (command_line: COLLECTION[STRING])
      do
         io.put_line(client.list_remotes)
      end

feature {ANY}
   help (command: COLLECTION[STRING]): STRING
      do
         Result := once "[
                          [33mremote list[0m
                                             Lists the known remotes.

                         ]"
      end

end -- class COMMAND_REMOTE_LIST
