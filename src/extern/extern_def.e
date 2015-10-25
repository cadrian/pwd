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
deferred class EXTERN_DEF

inherit
   TESTABLE

feature {EXTERN}
   makefifo (fifo: FIXED_STRING)
         -- create a named fifo
      require
         fifo /= Void
      deferred
      ensure
         exists(fifo)
      end

   tmp: FIXED_STRING
         -- create a temporary directory
      deferred
      ensure
         Result /= Void
      end

   exists (name: FIXED_STRING): BOOLEAN
         -- True if the file exists and is a fifo
      require
         name /= Void
      deferred
      end

   sleep (milliseconds: INTEGER_64)
      require
         milliseconds >= 0
      deferred
      end

   wait_for (name: FIXED_STRING)
      require
         name /= Void
      deferred
      end

   splice (input: INPUT_STREAM; output: OUTPUT_STREAM)
      require
         input.is_connected
         output.is_connected
      deferred
      end

   process_running (pid: INTEGER): BOOLEAN
      require
         pid > 0
      deferred
      end

end -- class EXTERN_DEF
