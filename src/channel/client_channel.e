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
deferred class CLIENT_CHANNEL

feature {CLIENT}
   server_running (when_reply: PROCEDURE[TUPLE[BOOLEAN]])
         -- True if the server is running, False otherwise
      require
         when_reply /= Void
      deferred
      end

   server_start
      deferred
      end

   call (query: MESSAGE; when_reply: PROCEDURE[TUPLE[MESSAGE]])
      require
         is_ready
         query /= Void
         when_reply /= Void
      deferred
      ensure
         is_ready
      end

   is_ready: BOOLEAN
      deferred
      end

   cleanup
      deferred
      end

end -- class CLIENT_CHANNEL
