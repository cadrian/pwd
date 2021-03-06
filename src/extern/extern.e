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
expanded class EXTERN
   --
   -- A façade to the actual extern implementation
   --

insert
   TEST_FACADE[EXTERN_DEF]

feature {ANY}
   make (fifo: FIXED_STRING)
         -- create a named fifo
      require
         fifo /= Void
      do
         def.makefifo(fifo)
      ensure
         exists(fifo)
      end

   tmp: FIXED_STRING
         -- create a temporary directory
      do
         Result := def.tmp
      ensure
         Result /= Void
      end

   exists (name: FIXED_STRING): BOOLEAN
         -- True if the file exists and is a fifo
      require
         name /= Void
      do
         Result := def.exists(name)
      end

   sleep (milliseconds: INTEGER_64)
      require
         milliseconds >= 0
      do
         def.sleep(milliseconds)
      end

   wait_for (name: FIXED_STRING)
      require
         name /= Void
      do
         def.wait_for(name)
      end

   splice (input: INPUT_STREAM; output: OUTPUT_STREAM)
      do
         def.splice(input, output)
      end

   process_running (pid: INTEGER): BOOLEAN
      require
         pid > 0
      do
         Result := def.process_running(pid)
      end

feature {}
   def_impl: EXTERN_IMPL
      once
         create Result
      end

end -- class EXTERN
