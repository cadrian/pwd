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
class SERVER_FIFO

inherit
   SERVER_CHANNEL

insert
   SHARED_FIFO
   LOGGING
   FILE_TOOLS

create {CHANNEL_FACTORY}
   make

feature {SERVER}
   command: RING_ARRAY[STRING]

   prepare (events: EVENTS_SET) is
      local
         t: TIME_EVENTS
      do
         if channel.is_connected then
            log.info.put_line(once "Awaiting connection.")
            events.expect(channel.event_can_read)
         else
            log.info.put_line(once "Channel not connected!")
            events.expect(t.timeout(0))
         end
      end

   is_ready (events: EVENTS_SET): BOOLEAN is
      do
         if events.event_occurred(channel.event_can_read) then
            channel.read_line
            Result := not channel.end_of_input and then not channel.last_string.is_empty
            if Result then
               log.info.put_line(once "Connection received")
            end
         end
      end

   continue is
      do
         command.clear_count
         channel.last_string.split_in(command)
         if command.is_empty then
            log.info.put_line(once "Received empty command")
         else
            log.info.put_line(once "Received command: #(1)" # command.first)
         end
      end

   done: BOOLEAN is
      do
         Result := not channel.is_connected
      end

   restart is
      do
         if not extern.exists(server_fifo) then
            extern.make(server_fifo)
            if not extern.exists(server_fifo) then
               log.error.put_line(once "Error while opening fifo #(1)" # server_fifo)
               die_with_code(1)
            end
         end

         channel.connect_to(server_fifo)
      end

   disconnect is
      do
         channel.disconnect
      end

   cleanup is
      do
         delete(server_fifo)
      end

feature {}
   make is
      do
         if extern.exists(server_fifo) then
            log.error.put_line(once "Fifo already exists, not starting server")
            die_with_code(1)
         end

         create command.with_capacity(16, 0)
         create channel.make
      end

   channel: TEXT_FILE_READ_WRITE
         -- There must be at least one writer for the server_fifo to be blocking in select(2)
         -- see http://stackoverflow.com/questions/580013/how-do-i-perform-a-non-blocking-fopen-on-a-named-pipe-mkfifo

invariant
   channel /= Void
   server_fifo /= Void

end
