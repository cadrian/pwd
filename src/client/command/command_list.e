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
class COMMAND_LIST

inherit
   COMMAND

create {CONSOLE}
   make

feature {COMMANDER}
   name: FIXED_STRING
      once
         Result := ("list").intern
      end

   run (command: COLLECTION[STRING])
      do
         inspect
            command.count
         when 0 then
            client.call_server(create {QUERY_LIST}.make(Void), agent when_reply(?))
         when 1 then
            client.call_server(create {QUERY_LIST}.make(command.first), agent when_reply(?))
         else
            error_and_help(message_invalid_arguments, command)
         end
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING]
      do
         Result := no_completion
      end

   help (command: COLLECTION[STRING]): STRING
      do
         Result := once "[
                          [33mlist {tag}[0m         List the known passwords (show only the keys).
                                             [33m{tag}[0m: optional tag to filter the keys to list

                         ]"
      end

feature {}
   when_reply (a_reply: MESSAGE)
      local
         reply: REPLY_LIST; string: STRING
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
               string := ""
               reply.for_each_name(agent (s, n: STRING)
                  do
                     s.append(n)
                     s.extend('%N')
                  end(string, ?))
               client.less(string)
            else
               error_and_help(reply.error, Void)
            end
         else
            log.error.put_line(once "Unexpected reply")
         end
      end

end -- class COMMAND_LIST
