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
class EXTERN_IMPL
   --
   -- originally POSIX fifo helpers, now misc helpers too
   --

inherit
   EXTERN_DEF
      redefine
         default_create
      end

insert
   LOGGING
      redefine
         default_create
      end

feature {}
   default_create
      do
         c_inline_h("#include <fcntl.h>%N")
         c_inline_h("#include <stdlib.h>%N")
         c_inline_h("#include <sys/stat.h>%N")
         c_inline_h("#include <sys/time.h>%N")
         c_inline_h("#include <sys/types.h>%N")
         c_inline_h("#include <unistd.h>%N")
      end

feature {EXTERN}
   makefifo (fifo: FIXED_STRING)
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
            log.error.put_line(once "Error #(1) while creating #(2)" # sts.out # fifo)
            crash
            die_with_code(1)
         end
      end

   tmp: FIXED_STRING
         -- create a temporary directory
      local
         t, p: POINTER; template: STRING
         shared: SHARED
      do
         template := (once "#(1)/XXXXXX" # shared.runtime_dir).out
         t := template.to_external
         c_inline_c("[
                     _p = mkdtemp((char*)_t);

                     ]")
         if not p.is_default then
            create Result.from_external_copy(p)
         end
      end

   exists (name: FIXED_STRING): BOOLEAN
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

   sleep (milliseconds: INTEGER_64)
      do
         c_inline_c("[
                     fd_set r,w,e;
                     struct timeval t;

                     t.tv_sec  = a1 / 1000;
                     t.tv_usec = (1000 * a1) % 1000000;
                     select(0, &r, &w, &e, &t);

                     ]")
      end

   wait_for (name: FIXED_STRING)
      do
         from
            sleep(25)
         until
            exists(name)
         loop
            sleep(25)
         end
      end

   splice (input: INPUT_STREAM; output: OUTPUT_STREAM)
      do
         from
            input.read_line
         until
            input.end_of_input
         loop
            output.put_line(input.last_string)
            input.read_line
         end
         output.put_string(input.last_string)
         output.flush
      end

   process_running (pid: INTEGER): BOOLEAN
      local
         proc: STRING
         p: POINTER; sts: INTEGER
      do
         proc := (once "/proc/#(1)" # pid.out).out
         p := proc.to_external
         c_inline_c("[
                     struct stat s;
                     int r = stat((const char*)_p, &s);
                     if (r == 0) {
                        _sts = S_ISDIR(s.st_mode) && s.st_uid == getuid();
                     } else {
                        _sts = 0;
                     }

                     ]")
         Result := sts /= 0
      end

end -- class EXTERN_IMPL
