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
class SERVER_SOCKET

inherit
   SERVER_CHANNEL
      export {SERVER_SOCKET_CONNECTION}
         fire_receive
      end

insert
   LOGGING

create {CHANNEL_FACTORY}
   make

feature {SERVER}
   prepare (events: EVENTS_SET) is
      do
         log.trace.put_line(once "Awaiting connection")
         events.expect(server.event_connection)
      end

   is_ready (events: EVENTS_SET): BOOLEAN is
      do
         Result := events.event_occurred(server.event_connection)
      end

   continue is
      local
         stream: SOCKET_INPUT_OUTPUT_STREAM
         job: SERVER_SOCKET_CONNECTION
      do
         log.trace.put_line(once "Connection received")
         stream := server.new_stream(True)
         create job.make(Current, stream)
         fire_new_job(job)
      end

   done: BOOLEAN is
      do
         Result := server = Void or else not server.can_connect
      end

   restart is
      local
         address: IPV4_ADDRESS
      do
         create address.make(127,0,0,1)
         create access.make(address, socket.port, False)
         server := access.server
         if server = Void then
            log.error.put_line(once "Server *not* started on port #(1)" # socket.port.out)
            die_with_code(1)
         else
            log.info.put_line(once "Started server on port #(1) (can connect: #(2))" # socket.port.out # server.can_connect.out)
         end
      end

   disconnect is
      do
         server.shutdown
      end

   cleanup is
      do
         -- nothing to do
      end

feature {}
   make is
      do
      end

   access: TCP_ACCESS
   server: SOCKET_SERVER

   socket: SOCKET

invariant
   done or else server /= Void

end
