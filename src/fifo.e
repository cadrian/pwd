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
--
-- originally POSIX fifo helpers, now misc helpers too
--

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
         -- create a named fifo
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
         -- create a temporary directory
      local
         p: POINTER; s: STRING
      do
         c_inline_c("[
                     char template[] = "/tmp/.pwd.XXXXXX";
                     _p = mkdtemp(template);

                     ]")
         if not p.is_default then
            create Result.from_external_copy(p)
         end
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

   sleep (milliseconds: INTEGER_64) is
      do
         c_inline_c("[
                     fd_set r,w,e;
                     struct timeval t;

                     t.tv_sec  = 0L;
                     t.tv_usec = a1;
                     select(0, &r, &w, &e, &t);

                     ]")
      end

   wait_for (name: FIXED_STRING) is
      do
         from
         until
            exists(name)
         loop
            sleep(10)
         end
      end

   splice (input: INPUT_STREAM; output: OUTPUT_STREAM) is
      require
         input.is_connected
         output.is_connected
      do
         from
            input.read_line
         until
            input.end_of_input or else input.last_string.is_empty
         loop
            output.put_line(input.last_string)
            input.read_line
         end
         output.put_string(input.last_string)
         output.flush
      end

end
