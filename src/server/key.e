-- This file is part of pwdmgr.
-- Copyright (C) 2012-2014 Cyril Adrian <cyril.adrian@gmail.com>
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
class KEY

insert
   STRING_HANDLER

create {ANY}
   decode, new

feature {ANY}
   name: FIXED_STRING

   pass: STRING
         -- note: MUST NOT be a fixed string because the interned
         -- strings are never released (hence visible in memory dumps)

   is_deleted: BOOLEAN is
      do
         Result := del_count > add_count
      end

   is_valid: BOOLEAN

   set_pass (a_pass: STRING) is
      require
         is_valid
         a_pass /= Void
      do
         clear
         pass := a_pass
         add_count := add_count + 1
      ensure
         pass = a_pass
         not is_deleted
      end

   delete is
      require
         is_valid
      do
         del_count := add_count + 1
      ensure
         is_deleted
      end

   encoded: ABSTRACT_STRING is
      do
         Result := encoder # name # add_count.out # del_count.out # pass
      end

   merge (other: like Current) is
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

   clear is
      do
         bzero(pass.storage, pass.capacity)
         pass.clear_count
      ensure
         pass.storage.all_default(pass.capacity)
         pass.count = 0
      end

feature {}
   bzero (buf: NATIVE_ARRAY[CHARACTER]; count: INTEGER) is
      external "plug_in"
      alias "[
         location: "."
         module_name: "plugin"
         feature_name: "bzero"
      ]"
      end

   decode (a_line: STRING) is
      require
         a_line /= Void
      local
         dat: STRING
      do
         if decoder.match(a_line) then
            dat := once ""
            is_valid := True

            dat.clear_count
            decoder.append_named_group(a_line, dat, once "name")
            name := dat.intern

            dat.clear_count
            decoder.append_named_group(a_line, dat, once "add")
            add_count := dat.to_integer

            dat.clear_count
            decoder.append_named_group(a_line, dat, once "del")
            del_count := dat.to_integer

            dat.clear_count
            decoder.append_named_group(a_line, dat, once "pass")
            pass := dat.twin

            bzero(dat.storage, dat.capacity)
            bzero(a_line.storage, a_line.capacity)
         end
      end

   new (a_name: ABSTRACT_STRING; a_pass: STRING) is
      require
         a_name /= Void
         a_pass /= Void
      do
         name := a_name.intern
         pass := a_pass
         is_valid := True
      ensure
         is_valid
         not is_deleted
      end

   decoder: REGULAR_EXPRESSION is
      local
         builder: REGULAR_EXPRESSION_BUILDER
      once
         Result := builder.convert_python_pattern("^(?P<name>[^:]+):(?P<add>[0-9]+):(?P<del>[0-9]+):(?P<pass>.*)$")
      end

   encoder: FIXED_STRING is
      once
         Result := "#(1):#(2):#(3):#(4)".intern
      end

feature {KEY}
   add_count: INTEGER
   del_count: INTEGER

invariant
   is_valid implies name /= Void
   pass /= Void

end
