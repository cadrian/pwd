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
class SERVER_SOCKET

inherit
   SERVER_CHANNEL
      export {SERVER_SOCKET_CONNECTION} fire_receive
      end

insert
   LOGGING

create {ANY}
   make

feature {SERVER}
   prepare (events: EVENTS_SET)
      do
         if not trace then
            log.trace.put_line(once "Awaiting connection")
            trace := True
         end
         events.expect(server.event_connection)
      end

   is_ready (events: EVENTS_SET): BOOLEAN
      do
         Result := events.event_occurred(server.event_connection)
         if Result then
            log.trace.put_line(once "Connection ready!")
            trace := False
         end
      end

   continue
      local
         stream: SOCKET_INPUT_OUTPUT_STREAM; job: SERVER_SOCKET_CONNECTION
      do
         log.trace.put_line(once "Connection received")
         stream := server.new_stream(True)
         if stream.error = Void then
            create job.make(Current, stream)
            fire_new_job(job)
         else
            log.error.put_line(once "Network error: #(1)" # stream.error)
         end
      end

   done: BOOLEAN
      do
         Result := server = Void or else not server.can_connect
      end

   restart
      local
         access: TCP_ACCESS; address: IPV4_ADDRESS
      do
         create address.make(127, 0, 0, 1)
         create access.make(address, socket.port, False)
         server := access.server
         if server = Void then
            log.error.put_line(once "Server *not* started on port #(1)" # socket.port.out)
            die_with_code(1)
         else
            log.info.put_line(once "Started server on port #(1) (can connect: #(2))" # socket.port.out # server.can_connect.out)
         end
      end

   disconnect
      do
         server.shutdown
      end

   cleanup
      do
         -- nothing to do
      end

feature {}
   make
      do
      end

   server: SOCKET_SERVER

   socket: SOCKET_CONF

   trace: BOOLEAN

invariant
   done or else server /= Void

end -- class SERVER_SOCKET
