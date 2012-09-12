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
      do
         channel.read_line
         command.clear_count
         channel.last_string.split_in(command)
         if command.is_empty then
            log.info.put_line(once "Received empty command, disconnecting")
            channel.disconnect
         else
            log.info.put_line(once "Received command: #(1)" # command.first)
            server.fire_receive(command)
         end
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
         create command.make(1, 0)
         server := a_server
         channel := a_channel
      ensure
         server = a_server
         channel = a_channel
      end

   command: RING_ARRAY[STRING]
   server: SERVER_SOCKET
   channel: SOCKET_INPUT_OUTPUT_STREAM

invariant
   command /= Void
   server /= Void
   channel /= Void

end
