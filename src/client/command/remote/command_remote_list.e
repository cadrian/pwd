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
class COMMAND_REMOTE_LIST

inherit
   COMMAND

create {COMMAND_REMOTE}
   make

feature {COMMANDER}
   name: FIXED_STRING is
      once
         Result := "list".intern
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING] is
      do
         Result := no_completion
      end

   run (command_line: COLLECTION[STRING]) is
      do
         io.put_line(client.list_remotes)
      end

feature {ANY}
   help (command: COLLECTION[STRING]): STRING is
      do
         Result := once "[
                          [33mremote list[0m
                                             Lists the known remotes.

                         ]"
      end

end
