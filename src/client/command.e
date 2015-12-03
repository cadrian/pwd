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
deferred class COMMAND

insert
   COMPLETION_TOOLS
   LOGGING

feature {COMMANDER}
   name: FIXED_STRING
         -- The command name
      deferred
      end

   clean
         -- Called before starting to read a command, for optional
         -- cleanup (e.g. completion results and so on)
         -- Does nothing by default.
      do
      end

   run (command: COLLECTION[STRING])
         -- run the command with the given arguments
      require
         client /= Void
         command /= Void
      deferred
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING]
         -- list possible completion words
      require
         client /= Void
         command /= Void
         word /= Void
      deferred
      end

   help (command: COLLECTION[STRING]): ABSTRACT_STRING
         -- If `command' is Void, provide extended help
         -- Otherwise provide help depending on the user input
      require
         client /= Void
      deferred
      end

feature {}
   error_and_help (message: ABSTRACT_STRING; command_line: COLLECTION[STRING])
      require
         message /= Void
      do
         std_output.put_string(once "[1m**** #(1)[0m%N#(2)%N" # message # help(command_line))
      end

   message_invalid_arguments: STRING "Invalid arguments"

feature {}
   data: RING_ARRAY[STRING]
      once
         create Result.with_capacity(16, 0)
      end

   make (a_client: like client; map: DICTIONARY[COMMAND, FIXED_STRING])
      require
         a_client /= Void
         map /= Void
         not map.fast_has(name)
      do
         client := a_client
         map.add(Current, name)
      ensure
         client = a_client
         map.fast_at(name) = Current
      end

   client: CONSOLE

invariant
   client /= Void

end -- class COMMAND
