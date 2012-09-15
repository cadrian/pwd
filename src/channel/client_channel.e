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
deferred class CLIENT_CHANNEL

feature {CLIENT}
   server_running: BOOLEAN is
         -- True if the server is running, False otherwise
      deferred
      end

   server_start is
      require
         not server_running
      deferred
      end

   call (query: MESSAGE; when_reply: PROCEDURE[TUPLE[MESSAGE]]) is
      require
         server_is_ready
         is_ready
         query /= Void
         when_reply /= Void
      deferred
      ensure
         is_ready
      end

   is_ready: BOOLEAN is
      deferred
      end

   server_is_ready: BOOLEAN is
      deferred
      end

   cleanup is
      deferred
      end

end
