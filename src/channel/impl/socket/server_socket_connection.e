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
class SERVER_SOCKET_CONNECTION

inherit
   JOB

insert
   LOGGING
   JSON_HANDLER

create {SERVER_SOCKET}
   make

feature {LOOP_ITEM}
   prepare (events: EVENTS_SET) is
      do
         log.info.put_line(once "Connection established, awaiting command")
         events.expect(channel.event_can_read)
      end

   is_ready (events: EVENTS_SET): BOOLEAN is
      do
         Result := events.event_occurred(channel.event_can_read)
      end

   continue is
      local
         json: JSON_TEXT; obj: JSON_OBJECT; query, reply: MESSAGE
         factory: MESSAGE_FACTORY
      do
         error := Void
         json := parser.parse_json_text(channel)

         if error /= Void or else not obj ?:= json then
            log.warning.put_line(once "Malformed request (#(1)). Discarding." # error)
         else
            obj ::= json
            query := factory.from_json(obj)
            reply := server.fire_receive(query)
            if reply = Void then
               log.warning.put_line("No reply to the query #(1)!" # query.command)
            else
               encoder.encode_in(reply.json, channel)
            end
         end
         channel.disconnect
      end

   done: BOOLEAN is
      do
         Result := not channel.is_connected
      end

   restart is
      do
      end

feature {}
   make (a_server: like server; a_channel: like channel) is
      require
         a_server /= Void
         a_channel /= Void
      do
         server := a_server
         channel := a_channel
         create parser.make(agent json_parse_error)
      ensure
         server = a_server
         channel = a_channel
      end

   json_parse_error (msg: ABSTRACT_STRING) is
      do
         error := msg.out
      end

   server: SERVER_SOCKET
   channel: SOCKET_INPUT_OUTPUT_STREAM

   parser: JSON_PARSER
   error: STRING

   encoder: JSON_ENCODER is
      once
         create Result.make
      end

invariant
   server /= Void
   channel /= Void
   parser /= Void

end
