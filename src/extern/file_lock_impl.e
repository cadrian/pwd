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
class FILE_LOCK_IMPL

inherit
   FILE_LOCK

insert
   LOGGING

create {FILE_LOCKER_IMPL}
   make

feature {ANY}
   read
      require
         not write_locked
         not read_locked
      do
         flock_lock_sh(stream.descriptor)
         lock_state := 1
         log.trace.put_line(once "Got read lock: #(1)" # stream.out)
      ensure
         read_locked
      end

   try_read
      require
         not write_locked
         not read_locked
      do
         if flock_try_lock_sh(stream.descriptor) then
            lock_state := 1
            log.trace.put_line(once "Got read lock: #(1)" # stream.out)
         end
      end

   read_locked: BOOLEAN
      do
         Result := lock_state = 1
      end

   write
      require
         not write_locked
         not read_locked
      do
         flock_lock_ex(stream.descriptor)
         lock_state := -1
         log.trace.put_line(once "Got write lock: #(1)" # stream.out)
      ensure
         write_locked
      end

   try_write
      require
         not write_locked
         not read_locked
      do
         if flock_try_lock_sh(stream.descriptor) then
            lock_state := -1
            log.trace.put_line(once "Got write lock: #(1)" # stream.out)
         end
      end

   write_locked: BOOLEAN
      do
         Result := lock_state = -1
      end

   done
      require
         locked
      do
         flock_unlock(stream.descriptor)
         lock_state := 0
         log.trace.put_line(once "Relinquished lock: #(1)" # stream.out)
      ensure
         not locked
      end

   locked: BOOLEAN
      do
         Result := lock_state /= 0
      end

feature {}
   make (a_stream: STREAM)
      require
         a_stream.has_descriptor
      do
         stream := a_stream
      ensure
         stream = a_stream
      end

   stream: STREAM

   lock_state: INTEGER_8

feature {}
   flock_lock_sh (fd: INTEGER)
      local
         r: INTEGER
      do
         c_inline_c("_r = flock(a1, LOCK_SH);%N")
         if r /= 0 then
            c_inline_c("perror(strerror(errno));%N")
            die_with_code(1)
         end
      end

   flock_try_lock_sh (fd: INTEGER): BOOLEAN
      local
         r: INTEGER
      do
         c_inline_c("_r = flock(a1, LOCK_SH | LOCK_NB);%N")
         Result := check_try(r)
      end

   flock_lock_ex (fd: INTEGER)
      local
         r: INTEGER
      do
         c_inline_c("_r = flock(a1, LOCK_EX);%N")
         if r /= 0 then
            c_inline_c("perror(strerror(errno));%N")
            die_with_code(1)
         end
      end

   flock_try_lock_ex (fd: INTEGER): BOOLEAN
      local
         r: INTEGER
      do
         c_inline_c("_r = flock(a1, LOCK_EX | LOCK_NB);%N")
         Result := check_try(r)
      end

   check_try (r: INTEGER): BOOLEAN
      do
         if r = 0 then
            Result := True
         else
            c_inline_c("if (errno == EWOULDBLOCK) {%N")
            check
               not Result
            end
            c_inline_c("} else {%Nperror(strerror(errno));%N")
            die_with_code(1)
            c_inline_c("}%N")
         end
      end

   flock_unlock (fd: INTEGER)
      local
         r: INTEGER
      do
         c_inline_c("_r = flock(a1, LOCK_UN);%N")
         if r /= 0 then
            c_inline_c("perror(strerror(errno));%N")
            die_with_code(1)
         end
      end

invariant
   stream.has_descriptor

end -- class FILE_LOCK_IMPL
