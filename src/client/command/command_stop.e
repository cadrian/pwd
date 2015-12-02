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
class COMMAND_STOP

inherit
   COMMAND

insert
   LOGGING

create {CONSOLE}
   make

feature {COMMANDER}
   name: FIXED_STRING
      once
         Result := ("stop").intern
      end

   run (command: COLLECTION[STRING])
      do
         if not command.is_empty then
            error_and_help(message_invalid_arguments, command)
         else
            log.trace.put_line(once "stopping server.")
            client.do_stop
         end
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING]
      do
         Result := no_completion
      end

   help (command: COLLECTION[STRING]): STRING
      do
         Result := once "[33mstop[0m               Stop the server and close the administration console."
      end

end -- class COMMAND_STOP
