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
      redefine
         make, clean
      end

insert
   READLINE_EXTERNALS

create {CONSOLE}
   make

feature {COMMANDER}
   name: FIXED_STRING
      once
         Result := ("list").intern
      end

   clean
      do
         tags := Void
         completing := False
      end

   run (command: COLLECTION[STRING])
      do
         inspect
            command.count
         when 0 then
            client.call_server(create {QUERY_LIST}.make(""), agent when_reply(?))
         when 1 then
            client.call_server(create {QUERY_LIST}.make(command.first), agent when_reply(?))
         else
            error_and_help(message_invalid_arguments, command)
         end
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING]
      do
         if command.count = 1 then
            Result := tags
            if Result = Void then
               std_output.put_string(once "...")
               std_output.flush
               if not completing then
                  client.call_server(create {QUERY_TAGS}.make, agent when_reply_tags(?))
               end
               Result := no_completion
            end
         else
            Result := no_completion
         end
      end

   help (command: COLLECTION[STRING]): STRING
      do
         Result := once "[
                          [33mlist {tag}[0m         List the known passwords (show only the keys).
                                             [33m{tag}[0m: optional tag to filter the keys to list

                         ]"
      end

feature {}
   make (a_client: like client; a_map: DICTIONARY[COMMAND, FIXED_STRING])
      do
         Precursor(a_client, a_map)
         map := a_map
      end

   map: DICTIONARY[COMMAND, FIXED_STRING]
   completing: BOOLEAN
   tags: TRAVERSABLE[FIXED_STRING]

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

   when_reply_tags (a_reply: MESSAGE)
      local
         reply: REPLY_TAGS; taglist: FAST_ARRAY[FIXED_STRING]
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
               create taglist.with_capacity(reply.count_names)
               reply.for_each_name(agent (tag: STRING; t: FAST_ARRAY[FIXED_STRING])
                                      do
                                         t.add_last(tag.intern)
                                      end (?, taglist))
               tags := taglist
            else
               tags := no_completion
            end
         else
            log.error.put_line(once "Unexpected reply")
            tags := no_completion
         end
         rl_redisplay
      end

end -- class COMMAND_LIST
