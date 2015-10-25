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
class CHANNEL_FACTORY_IMPL

inherit
   CHANNEL_FACTORY_DEF

insert
   LOGGING

feature {CHANNEL_FACTORY}
   new_client_channel (tmpdir: ABSTRACT_STRING): CLIENT_CHANNEL
      do
         inspect
            shared.channel_method.out
         when "fifo" then
            create {CLIENT_FIFO} Result.make(tmpdir)
         when "socket" then
            create {CLIENT_SOCKET} Result.make(tmpdir)
         when "zmq" then
            create {CLIENT_ZMQ} Result.make(tmpdir)
         else
            log.error.put_line(once "Unknown channel method: #(1)" # shared.channel_method)
            die_with_code(1)
         end
      end

   new_server_channel: SERVER_CHANNEL
      do
         inspect
            shared.channel_method.out
         when "fifo" then
            create {SERVER_FIFO} Result.make
         when "socket" then
            create {SERVER_SOCKET} Result.make
         when "zmq" then
            create {SERVER_ZMQ} Result.make
         else
            log.error.put_line(once "Unknown channel method: #(1)" # shared.channel_method)
            die_with_code(1)
         end
      end

feature {}
   shared: SHARED

end -- class CHANNEL_FACTORY_IMPL
