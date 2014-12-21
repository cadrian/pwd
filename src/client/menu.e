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
class MENU

inherit
   CLIENT

create {}
   make

feature {}
   run
      do
         send_menu
      end

   list: FAST_ARRAY[STRING]

   send_menu
      require
         channel.is_ready
      do
         call_server(create {QUERY_LIST}.make, agent when_list({MESSAGE}))
         if list /= Void and then not list.is_empty then
            display_menu
         end
      end

   when_list (a_reply: MESSAGE)
      local
         reply: REPLY_LIST
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
               create list.with_capacity(reply.count_names)
               reply.for_each_name(agent list.add_last({STRING}))
            else
               log.error.put_line(reply.error)
            end
         else
            log.error.put_line(once "Unexpected reply")
         end
      end

   display_menu
      require
         list /= Void
      local
         proc: PROCESS; proc_input: OUTPUT_STREAM; entry: STRING
      do
         proc := processor.execute_redirect(conf(config_command), conf_no_eval(config_arguments))
         if proc.is_connected then
            proc_input := proc.input
            list.for_each(agent display(?, proc_input))
            proc_input.disconnect
            proc.output.read_line
            if not proc.output.end_of_input then
               entry := proc.output.last_string.twin
            end

            proc.wait
            if proc.status = 0 and then entry /= Void and then not entry.is_empty then
               do_get(entry, agent copy_to_clipboard(?), agent
                  do
                  end)
            end
         end
      end

   display (line: STRING; output: OUTPUT_STREAM)
      require
         list /= Void
         output.is_connected
      do
         output.put_line(line)
      end

   config_command: FIXED_STRING
      once
         Result := ("command").intern
      end

   config_arguments: FIXED_STRING
      once
         Result := ("arguments").intern
      end

   unknown_key (key: ABSTRACT_STRING)
      do
         check
            False
         end
      end

end -- class MENU
