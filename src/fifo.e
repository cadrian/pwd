-- This file is part of pwdmgr.
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
expanded class FIFO

insert
   ARGUMENTS

feature {ANY}
   make (fifo: FIXED_STRING) is
      local
         path: POINTER; sts: INTEGER
      do
         c_inline_h("#include <sys/types.h>%N")
         c_inline_h("#include <sys/stat.h>%N")
         c_inline_h("#include <fcntl.h>%N")
         c_inline_h("#include <unistd.h>%N")
         path := fifo.to_external
         c_inline_c("[
                     _sts = mknod((const char*)_path, S_IFIFO | 0600, 0);
                     if (_sts == -1)
                        _sts = errno;

                     ]")
         if sts /= 0 then
            std_error.put_line(once "#(1): error #(2) while creating #(3)" # command_name # sts.out # fifo)
            die_with_code(1)
         end
      end

end
