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
class SERVER_SOCKET_CONNECTION

inherit
   JOB
      redefine
         out_in_tagged_out_memory
      end

insert
   LOGGING
      redefine
         out_in_tagged_out_memory
      end

create {SERVER_SOCKET}
   make

feature {ANY}
   out_in_tagged_out_memory
      do
         tagged_out_memory.append(once "{SERVER_SOCKET_CONNECTION#")
         id.append_in(tagged_out_memory)
         tagged_out_memory.extend('}')
      end

feature {LOOP_ITEM}
   prepare (events: EVENTS_SET)
      do
         if reply = Void then
            log.trace.put_line(out + ": Connection established, awaiting query")
            events.expect(channel.event_can_read)
         else
            log.trace.put_line(out + ": Reply ready, awaiting client")
            events.expect(channel.event_can_write)
         end
      end

   is_ready (events: EVENTS_SET): BOOLEAN
      do
         if done then
            Result := True
         elseif reply = Void then
            Result := events.event_occurred(channel.event_can_read)
            if Result then
               log.trace.put_line(out + ": Connection input ready")
            end
         else
            Result := events.event_occurred(channel.event_can_write)
            if Result then
               log.trace.put_line(out + ": Connection output ready")
            end
         end
      end

   continue
      do
         if not done then
            if reply = Void then
               streamer.read_message(channel)
               if streamer.error /= Void then
                  if channel.is_connected then
                     log.warning.put_line(out + ": #(1). Closing connection." # streamer.error)
                     channel.disconnect
                  else
                     log.info.put_line(out + ": #(1). Connection was closed." # streamer.error)
                  end
               else
                  query := streamer.last_message
                  if query = Void then
                     if channel.is_connected then
                        log.trace.put_line(out + ": No query, invalid message? Closing connection.")
                        channel.disconnect
                     else
                        log.trace.put_line(out + ": No query, connection was closed.")
                     end
                  else
                     log.info.put_line(out + ": Connection received: type #(1) command #(2)." # query.type # query.command)
                     reply := server.fire_receive(query)
                     if reply = Void then
                        log.warning.put_line(out + ": No reply to the query #(1)! Closing connection." # query.command)
                        channel.disconnect
                     end
                  end
               end
            else
               log.trace.put_line(out + ": Replying: type #(1) command #(2)." # reply.type # reply.command)
               streamer.write_message(reply, channel)
               channel.flush
               done := True
               log.trace.put_line(out + ": Done.")
            end
         end
      end

   done: BOOLEAN

   restart
      do
         check
            False
         end
      end

feature {}
   make (a_server: like server; a_channel: like channel)
      require
         a_server /= Void
         a_channel /= Void
      do
         counter.increment
         id := counter.item
         server := a_server
         channel := a_channel
         a_channel.when_disconnect(agent on_channel_disconnect(?))
      ensure
         server = a_server
         channel = a_channel
      end

   id: INTEGER
   server: SERVER_SOCKET
   channel: SOCKET_INPUT_OUTPUT_STREAM
   query, reply: MESSAGE

   streamer: MESSAGE_STREAMER
      once
         create Result.make
      end

   on_channel_disconnect (a_channel: like channel)
      do
         check
            a_channel = channel
         end
         log.trace.put_line(out + ": Channel disconnected.")
         if a_channel.error /= Void then
            log.warning.put_line(out + ": Socket error: #(1)" # a_channel.error)
         end
         done := True
         --| **** TODO query.clean
         --| **** TODO reply.clean
      end

   counter: COUNTER
      once
         create Result
      end

invariant
   server /= Void
   channel /= Void

end -- class SERVER_SOCKET_CONNECTION
