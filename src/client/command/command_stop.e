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
class COMMAND_STOP

inherit
   COMMAND

create {CLIENT}
   make

feature {CLIENT}
   name: FIXED_STRING is
      once
         Result := "stop".intern
      end

   run (command: COLLECTION[STRING]) is
      do
         log.info.put_line(once "stopping server.")
         send("stop")
         client.do_stop
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
         Result := once "[33mstop[0m               Stop the server and close the administration console."
      end

end
