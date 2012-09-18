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
         log.trace.put_line(once "Connection established, awaiting command")
         events.expect(channel.event_can_read)
      end

   is_ready (events: EVENTS_SET): BOOLEAN is
      do
         Result := done or else events.event_occurred(channel.event_can_read)
      end

   continue is
      local
         query, reply: MESSAGE
      do
         if not done then
            streamer.read_message(channel)
            if streamer.error /= Void then
               log.warning.put_line(once "Error: #(1). Closing connection." # streamer.error)
               channel.disconnect
            else
               query := streamer.last_message
               if query = Void then
                  log.trace.put_line(once "No query, connection closed?")
                  channel.disconnect
               else
                  log.info.put_line(once "Connection received: type #(1) command #(2)." # query.type # query.command)
                  reply := server.fire_receive(query)
                  if reply = Void then
                     log.warning.put_line("No reply to the query #(1)!" # query.command)
                  else
                     log.trace.put_line(once "Replying: type #(1) command #(2)." # reply.type # reply.command)
                     streamer.write_message(reply, channel)
                     channel.flush
                  end
               end
            end
         end
      end

   done: BOOLEAN

   restart is
      do
         check False end
      end

feature {}
   make (a_server: like server; a_channel: like channel) is
      require
         a_server /= Void
         a_channel /= Void
      do
         server := a_server
         channel := a_channel
         a_channel.when_disconnect(agent on_channel_disconnect)
      ensure
         server = a_server
         channel = a_channel
      end

   server: SERVER_SOCKET
   channel: SOCKET_INPUT_OUTPUT_STREAM

   streamer: MESSAGE_STREAMER is
      once
         create Result.make
      end

   on_channel_disconnect (a_channel: like channel) is
      do
         check
            a_channel = channel
         end
         done := True
      end

invariant
   server /= Void
   channel /= Void

end
