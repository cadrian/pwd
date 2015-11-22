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
class KEY

create {ANY}
   new

create {VAULT_FILE}
   from_file

feature {ANY}
   name: FIXED_STRING
   pass: STRING

   is_deleted: BOOLEAN
      do
         Result := del_count > add_count
      end

   set_pass (a_pass: STRING)
      require
         a_pass /= Void
      do
         clear
         pass := a_pass
         add_count := add_count + 1
      ensure
         pass = a_pass
         not is_deleted
      end

   delete
      do
         del_count := add_count + 1
      ensure
         is_deleted
      end

   merge (other: like Current)
      require
         other.name = name
      do
         if del_count < other.del_count then
            del_count := other.del_count
         end
         if add_count < other.add_count then
            pass := other.pass
            add_count := other.add_count
         end
      end

   clear
      local
         bzero: BZERO
      do
         bzero(pass)
      ensure
         pass.is_empty
      end

feature {}
   new (a_name: ABSTRACT_STRING; a_pass: STRING)
      require
         a_name /= Void
         a_pass /= Void
      do
         from_file(a_name, a_pass, 0, 0)
      ensure
         not is_deleted
      end

   from_file (a_name: ABSTRACT_STRING; a_pass: STRING; a_add_count, a_del_count: INTEGER)
      require
         a_name /= Void
         a_pass /= Void
         a_add_count >= 0
         a_del_count >= 0
      do
         name := a_name.intern
         pass := a_pass
         add_count := a_add_count
         del_count := a_del_count
      ensure
         name = a_name.intern
         pass = a_pass
         add_count = a_add_count
         del_count = a_del_count
      end

feature {KEY, VAULT_FILE}
   add_count: INTEGER
   del_count: INTEGER

invariant
   pass /= Void

end -- class KEY
