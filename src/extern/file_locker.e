-- This file is part of pwd.
-- Copyright (C) 2012-2014 Cyril Adrian <cyril.adrian@gmail.com>
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
expanded class FILE_LOCKER

feature {ANY}
   lock (a_stream: STREAM): FILE_LOCK
      require
         a_stream.has_descriptor
      local
         p: POINTER
      do
         c_inline_h("#include <sys/file.h>%N")

         p := a_stream.to_pointer
         Result := locks.fast_reference_at(p)
         if Result = Void then
            create Result.make(a_stream)
            locks.add(Result, p)
         end
      ensure
         Result /= Void
      end

feature {}
   locks: HASHED_DICTIONARY[FILE_LOCK, POINTER]
      once
         create Result
      end

end
