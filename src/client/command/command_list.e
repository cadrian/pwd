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
class COMMAND_LIST

inherit
   COMMAND

create {CONSOLE}
   make

feature {COMMANDER}
   name: FIXED_STRING is
      once
         Result := "list".intern
      end

   run (command: COLLECTION[STRING]) is
      do
         if not command.is_empty then
            error_and_help(message_invalid_arguments, command)
         else
            client.call_server(once "list", Void,
                               agent (stream: INPUT_STREAM) is
                               local
                                  str: STRING_OUTPUT_STREAM
                                  extern: EXTERN
                               do
                                  create str.make
                                  extern.splice(stream, str)
                                  client.less(str.to_string)
                               end)
         end
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING] is
      do
         Result := no_completion
      end

   help (command: COLLECTION[STRING]): STRING is
      do
         Result := once "[33mlist[0m               List the known passwords (show only the keys)."
      end

end
