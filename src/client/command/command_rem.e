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
class COMMAND_REM

inherit
   COMMAND

create {CLIENT}
   make

feature {CLIENT}
   name: FIXED_STRING is
      once
         Result := "rem".intern
      end

   run (command: COLLECTION[STRING]) is
      do
         call_server(once "unset", command.first,
                     agent (stream: INPUT_STREAM) is
                        do
                           stream.read_line
                           if not stream.end_of_input then
                              xclip(once "")
                              io.put_line(once "[1mDone[0m")
                           end
                        end)
         send_save
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING] is
      do
         create {FAST_ARRAY[FIXED_STRING]} Result.make(0)
      end

feature {ANY}
   help (command: COLLECTION[STRING]): STRING is
         -- If `command' is Void, provide extended help
         -- Otherwise provide help depending on the user input
      do
         Result := once "[33mrem <key>[0m          Removes the password corresponding to the given key."
      end

end
