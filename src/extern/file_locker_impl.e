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
class FILE_LOCKER_IMPL

inherit
   FILE_LOCKER_DEF

feature {FILE_LOCKER}
   lock (a_stream: STREAM): FILE_LOCK_IMPL
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
      end

feature {}
   locks: HASHED_DICTIONARY[FILE_LOCK_IMPL, POINTER]
      once
         create Result
      end

end
