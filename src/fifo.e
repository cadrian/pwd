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
      redefine
         default_create
      end

feature {}
   default_create is
      do
         c_inline_h("#include <fcntl.h>%N")
         c_inline_h("#include <stdlib.h>%N")
         c_inline_h("#include <sys/stat.h>%N")
         c_inline_h("#include <sys/time.h>%N")
         c_inline_h("#include <sys/types.h>%N")
         c_inline_h("#include <unistd.h>%N")
      end

feature {ANY}
   make (fifo: FIXED_STRING) is
      local
         path: POINTER; sts: INTEGER
      do
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

   tmp: FIXED_STRING is
      local
         p: POINTER; s: STRING
      do
         c_inline_c("[
                     char template[11] = %"pwd.XXXXXX%";
                     _p = mkdtemp(template);

                     ]")
         if not p.is_default then
            create s.from_external_copy(p)
            s.append(once "/fifo")
            create Result.make_from_string(s)
            make(Result)
         end
      ensure
         Result /= Void implies Result.has_suffix(once "/fifo")
      end

   exists (name: FIXED_STRING): BOOLEAN is
         -- True if the file exists and is a fifo
      local
         p: POINTER; sts: INTEGER
      do
         p := name.to_external
         c_inline_c("[
                     struct stat s;
                     int r = stat((const char*)_p, &s);
                     if (r == 0) {
                        _sts = S_ISFIFO(s.st_mode);
                     } else {
                        _sts = 0;
                     }

                     ]")
         Result := sts /= 0
      end

   wait_for (name: FIXED_STRING) is
      do
         from
            c_inline_c("[
                        fd_set r,w,e;
                        struct timeval t;

                        ]")
         until
            exists(name)
         loop
            c_inline_c("[
                        t.tv_sec  = 0L;
                        t.tv_usec = 10000L; // sleep for 10 milliseconds
                        select(0, &r, &w, &e, &t);

                        ]")
         end
      end

end
