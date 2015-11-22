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
class VAULT

insert
   LOGGING
      rename
         io as any_io
      end

create {ANY}
   make

feature {ANY}
   is_open: BOOLEAN
      do
         Result := io /= Void and then io.is_open
      end

feature {ANY}
   close
      require
         is_open
      do
         if dirty then
            log.warning.put_line("**** CLOSING DIRTY VAULT!")
         end
         data.for_each(agent (key: KEY)
            do
               key.clear
            end(?))
         data.clear_count
         io.close
         io := Void
         log.info.put_line(once "Vault closed.")
      ensure
         not is_open
      end

   open (master: STRING)
      require
         master /= Void
         not is_open
      local
         error: ABSTRACT_STRING; file: VAULT_FILE
      do
         io := io_provider.item([master])
         if io = Void then
            log.error.put_line(once "VAULT NOT OPEN! no file provided")
         else
            create {LEGACY_FILE} file
            error := file.load(data, io)
            if error.is_empty then
               log.info.put_line(once "Vault is open")
               if data.is_empty then
                  -- new or empty vault, will force save
                  dirty := True
               end
            else
               log.info.put_line(once "VAULT NOT OPEN! #(1)" # error)
            end
         end
      end

   pass (key_name: STRING): STRING
      require
         is_open
         key_name /= Void
      local
         key: KEY
      do
         key := data.reference_at(key_name.intern)
         if key /= Void then
            Result := key.pass
         end
      end

   count: INTEGER
      do
         Result := data.count
      end

   for_each_key (action: PROCEDURE[TUPLE[FIXED_STRING]])
      require
         is_open
         action /= Void
      do
         data.for_each(agent (a: PROCEDURE[TUPLE[FIXED_STRING]]; k: KEY; n: FIXED_STRING)
            do
               if not k.is_deleted then
                  a.call([n])
               end
            end(action, ?, ?))
      end

   merge (other: like Current): ABSTRACT_STRING
      require
         is_open
         other.is_open
      do
         data.for_each_item(agent merge_other(other.data, ?))
         other.data.for_each_item(agent add_key(?))
         dirty := True
         Result := once ""
      end

   save: ABSTRACT_STRING
      require
         is_open
      local
         file: VAULT_FILE
      do
         if dirty then
            create {LEGACY_FILE} file
            Result := file.save(data, io)
            if Result.is_empty then
               dirty := False
            end
         else
            Result := once ""
         end
      ensure
         Result /= Void
         Result.is_empty = not dirty
      end

   set_random (a_name, a_recipe: STRING): ABSTRACT_STRING
      require
         is_open
         a_name /= Void
         a_recipe /= Void
      local
         pass_: STRING
      do
         pass_ := generate_pass(a_recipe)
         if pass_ = Void then
            Result := once "Invalid recipe"
         else
            Result := set(a_name, pass_)
         end
      ensure
         Result /= Void
         Result.is_empty implies dirty
      end

   set (a_name, a_pass: STRING): ABSTRACT_STRING
      require
         is_open
         a_name /= Void
         a_pass /= Void
      local
         key: KEY
      do
         key := data.reference_at(a_name.intern)
         if key = Void then
            create key.new(a_name, a_pass)
            data.add(key, key.name)
         else
            key.set_pass(a_pass)
         end

         dirty := True
         Result := once ""
      ensure
         dirty
      end

   unset (a_name: STRING): ABSTRACT_STRING
      require
         is_open
         a_name /= Void
      local
         key: KEY
      do
         key := data.reference_at(a_name.intern)
         if key /= Void and then not key.is_deleted then
            key.delete
            dirty := True
         end

         Result := once ""
      end

feature {}
   merge_other (other: like data; key: KEY)
      local
         other_key: KEY
      do
         other_key := other.reference_at(key.name)
         if other_key /= Void then
            key.merge(other_key)
         end
      end

   add_key (key: KEY)
      do
         data.add(key, key.name)
      end

feature {}
   generate_pass (recipe: ABSTRACT_STRING): STRING
      require
         recipe /= Void
      local
         g: PASS_GENERATOR
      do
         log.trace.put_line(once "generating random pass (may take time, depending on the system entropy)")
         create g.parse(recipe)
         if g.is_valid then
            Result := g.generated
         else
            log.warning.put_line(once "Invalid recipe: #(1)" # recipe)
         end
      end

feature {VAULT}
   data: AVL_DICTIONARY[KEY, FIXED_STRING]

feature {}
   make (a_io_provider: like io_provider)
      require
         a_io_provider /= Void
      do
         io_provider := a_io_provider
         create data.make
      ensure
         io_provider = a_io_provider
      end

   dirty: BOOLEAN
   io_provider: FUNCTION[TUPLE[STRING], VAULT_IO]
   io: VAULT_IO

invariant
   io_provider /= Void
   data /= Void
   data.for_all(agent (key: KEY; name: FIXED_STRING): BOOLEAN
      do
         Result := key /= Void and then name = key.name and then key.is_valid
      end(?, ?))
   not is_open implies data.is_empty

end -- class VAULT
