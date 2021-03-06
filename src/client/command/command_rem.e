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
class COMMAND_REM

inherit
   COMMAND

create {CONSOLE}
   make

feature {COMMANDER}
   name: FIXED_STRING
      once
         Result := ("rem").intern
      end

   run (command: COLLECTION[STRING])
      do
         if command.count /= 1 then
            error_and_help(message_invalid_arguments, command)
         else
            client.call_server(create {QUERY_UNSET}.make(command.first), agent when_reply(?))
         end
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING]
      do
         Result := no_completion
      end

   help (command: COLLECTION[STRING]): STRING
      do
         Result := once "[33mrem <key>[0m          Removes the password corresponding to the given key."
      end

feature {}
   when_reply (a_reply: MESSAGE)
      local
         reply: REPLY_UNSET
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
               client.copy_to_clipboard(once "")
               io.put_line(once "[1mDone[0m")
               if not client.send_save then
                  std_output.put_line(once "Failed to save the vault!")
               end
            else
               error_and_help(reply.error, Void)
            end
         else
            log.error.put_line(once "Unexpected reply")
         end
      end

end -- class COMMAND_REM
