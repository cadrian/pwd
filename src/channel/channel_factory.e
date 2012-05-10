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
expanded class CHANNEL_FACTORY

insert
   LOGGING

feature {CLIENT}
   new_client_channel (tmpdir: ABSTRACT_STRING): CLIENT_CHANNEL is
      require
         tmpdir /= Void
      do
         inspect
            shared.channel_method.out
         when "fifo" then
            create {CLIENT_FIFO} Result.make(tmpdir)
         else
            log.error.put_line(once "Unknown channel method: #(1)" # shared.channel_method)
            die_with_code(1)
         end
      end

feature {SERVER}
   new_server_channel: SERVER_CHANNEL is
      do
         inspect
            shared.channel_method.out
         when "fifo" then
            create {SERVER_FIFO} Result.make
         else
            log.error.put_line(once "Unknown channel method: #(1)" # shared.channel_method)
            die_with_code(1)
         end
      end

feature {}
   shared: SHARED

end