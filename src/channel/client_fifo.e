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
class CLIENT_FIFO

inherit
   CLIENT_CHANNEL

insert
   CONFIGURABLE
   FILE_TOOLS

create {CHANNEL_FACTORY}
   make

feature {CLIENT}
   send (string: ABSTRACT_STRING) is
      local
         tfw: TEXT_FILE_WRITE
      do
         create tfw.connect_to(server_fifo)
         if tfw.is_connected then
            tfw.put_line(string)
            tfw.flush

            -- give time to the OS and the server to get the message before closing the connection
            fifo.sleep(100)

            tfw.disconnect
         end
      end

   call (verb, arguments: ABSTRACT_STRING; action: PROCEDURE[TUPLE[INPUT_STREAM]]) is
      local
         tfr: TEXT_FILE_READ
      do
         fifo.make(client_fifo)
         if arguments = Void then
            send(once "#(1) #(2)" # verb # client_fifo)
         else
            send(once "#(1) #(2) #(3)" # verb # client_fifo # arguments)
         end
         fifo.wait_for(client_fifo)
         create tfr.connect_to(client_fifo)
         if tfr.is_connected then
            action.call([tfr])
            tfr.disconnect
            delete(client_fifo)
         end
      end

   is_ready: BOOLEAN is
      do
         Result := not fifo.exists(client_fifo)
      end

   server_is_ready: BOOLEAN is
      do
         Result := fifo.exists(server_fifo)
      end

   cleanup is
      do
         if fifo.exists(client_fifo) then
            delete(client_fifo)
         end
         delete(client_fifo.substring(client_fifo.lower, client_fifo.upper - 5)) -- "/fifo".count
      end

feature {}
   client_fifo: FIXED_STRING
   fifo: FIFO
   shared: SHARED

   make (tmpdir: ABSTRACT_STRING) is
      require
         tmpdir /= Void
      do
         client_fifo := ("#(1)/fifo" # tmpdir).intern
      end

   server_fifo: FIXED_STRING is
      do
         Result := shared.server_fifo
      end

invariant
   client_fifo /= Void

end
