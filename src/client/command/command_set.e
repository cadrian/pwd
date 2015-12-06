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
class COMMAND_SET

inherit
   COMMAND

create {CONSOLE}
   make

feature {COMMANDER}
   name: FIXED_STRING
      once
         Result := ("set").intern
      end

   run (command: COLLECTION[STRING])
      local
         query: QUERY_PROPERTY; property: STRING
      do
         if command.count = 3 then
            property := command.item(command.lower + 1)
            inspect
               property
            when "username", "url", "tag" then
               create query.make(command.first, once "set", property, command.last)
               client.call_server(query, agent when_reply(?))
            else
               error_and_help(once "Unrecognized argument '#(1)'" # command.last, command)
            end
         else
            error_and_help(message_invalid_arguments, command)
         end
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING]
      do
         if command.count = 2 then
            Result := filter_completions(complete_property, word)
         else
            Result := no_completion
         end
      end

   help (command: COLLECTION[STRING]): STRING
      do
         Result := once "[
                    [33mset <key> <property> <value>[0m    Set a key property.
                                       [33m<property>[0m is "username", "url", or "tag".

                         ]"
      end

feature {}
   complete_property: ITERATOR[FIXED_STRING] once then {FAST_ARRAY[FIXED_STRING] << ("username").intern, ("url").intern, ("tag").intern >> }.new_iterator end

   when_reply (a_reply: MESSAGE)
      local
         reply: REPLY_PROPERTY
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
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

end -- class COMMAND_SET
