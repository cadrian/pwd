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
class COMMAND_VERSION

inherit
   COMMAND

create {CONSOLE}
   make

feature {COMMANDER}
   name: FIXED_STRING
      once
         Result := ("version").intern
      end

   run (command: COLLECTION[STRING])
      do
         if not command.is_empty then
            error_and_help(message_invalid_arguments, command)
         else
            client.call_server(create {QUERY_VERSION}.make, agent when_reply(?))
         end
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING]
      do
         Result := no_completion
      end

   help (command: COLLECTION[STRING]): STRING
      do
         Result := once "[33mversion[0m            Display the server version."
      end

feature {}
   when_reply (a_reply: MESSAGE)
      local
         reply: REPLY_VERSION
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
               io.put_string("Client version: ")
               io.put_line(version)
               io.put_string("Server version: ")
               io.put_line(reply.version)
            else
               error_and_help(reply.error, Void)
            end
         else
            log.error.put_line(once "Unexpected reply")
         end
      end

end -- class COMMAND_VERSION
