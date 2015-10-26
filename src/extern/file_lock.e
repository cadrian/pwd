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
deferred class FILE_LOCK

insert
   LOGGING

feature {ANY}
   read
      require
         not write_locked
         not read_locked
      deferred
      ensure
         read_locked
      end

   try_read
      require
         not write_locked
         not read_locked
      deferred
      end

   read_locked: BOOLEAN
      deferred
      end

   write
      require
         not write_locked
         not read_locked
      deferred
      ensure
         write_locked
      end

   try_write
      require
         not write_locked
         not read_locked
      deferred
      end

   write_locked: BOOLEAN
      deferred
      end

   done
      require
         locked
      deferred
      ensure
         not locked
      end

   locked: BOOLEAN
      deferred
      end

end -- class FILE_LOCK
