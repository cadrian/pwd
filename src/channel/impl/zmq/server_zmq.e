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
class SERVER_ZMQ

inherit
   SERVER_CHANNEL

create {CHANNEL_FACTORY}
   make

feature {SERVER}
   prepare (events: EVENTS_SET)
      do
         if not trace then
            log.trace.put_line(once "Awaiting connection")
            trace := True
         end
         events.expect(socket.input_event.event_can_read)
      end

   is_ready (events: EVENTS_SET): BOOLEAN
      do
         Result := events.event_occurred(socket.input_event.event_can_read)
         if Result then
            log.trace.put_line(once "Connection ready!")
            trace := False
         end
      end

   continue
      local
         sis: STRING_INPUT_STREAM; sos: STRING_OUTPUT_STREAM
         f: EZMQ_FLAGS; s: STRING
         query, reply: MESSAGE
      do
         log.trace.put_line(once "Connection received")
         if socket.input_event.can_read_socket then
            socket.receive(16384, f.None)
            create sis.from_string(socket.last_received)
            s := once ""
            if streamer.error /= Void then
               log.warning.put_line(once "Error: #(1)" # streamer.error)
            else
               query := streamer.last_message
               if query = Void then
                  log.trace.put_line(once "No query?!")
               else
                  log.info.put_line(once "Connection received: type #(1) command #(2)." # query.type # query.command)
                  reply := fire_receive(query)
                  if reply = Void then
                     log.warning.put_line("No reply to the query #(1)!" # query.command)
                  else
                     log.trace.put_line(once "Replying: type #(1) command #(2)." # reply.type # reply.command)
                     create s.with_capacity(16384)
                     create sos.connect_to(s)
                     streamer.write_message(reply, sos)
                  end
               end
            end
            if socket.input_event.can_write_socket then
               socket.send(s, f.Dontwait)
            end
         end
      end

   done: BOOLEAN then not socket.is_connected end

   restart
      do
         check False end
         crash
      end

   disconnect
      do
         socket.disconnect
      end

   cleanup
      do
         -- nothing to do
      end

feature {}
   make
      local
         t: EZMQ_TYPE
         endpoint: EZMQ_ENDPOINT
      do
         create {EZMQ_ENDPOINT_ZMQ} endpoint.tcp(zmq.address, zmq.port)
         create {EZMQ_SOCKET_ZMQ_CONNECT} socket.make(t.Rep, endpoint)
      end

   socket: EZMQ_SOCKET

   zmq: ZMQ

   trace: BOOLEAN

   streamer: MESSAGE_STREAMER
      once
         create Result.make
      end

end -- class SERVER_ZMQ
