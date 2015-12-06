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
   CONFIGURABLE
   LOGGING
   KEY_HANDLER

create {ANY}
   make

feature {ANY}
   is_open: BOOLEAN
      do
         Result := inout /= Void and then inout.is_open
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
         inout.close
         inout := Void
         log.info.put_line(once "Vault closed.")
      ensure
         not is_open
      end

   open (master: STRING)
      require
         master /= Void
         not is_open
      local
         error, error2: ABSTRACT_STRING
         bzero: BZERO
      do
         inspect
            format
         when "legacy" then
            log.trace.put_line("Opening with legacy file provider")
            error := open_with(master, Legacy_file_provider())
         when "json" then
            log.trace.put_line("Opening with JSON file provider")
            error := open_with(master, Json_file_provider())
            if error.is_empty and then data.is_empty then
               error := "empty vault"
            end
            if not error.is_empty then
               log.trace.put_line("JSON file provider failed: #(1)" # error)
               if inout /= Void then
                  inout.close
               end
               -- Try the legacy format, transition only (will be
               -- saved in the JSON format)
               log.trace.put_line("Opening with legacy file provider")
               error2 := open_with(master, Legacy_file_provider())
               if error2.is_empty then
                  error := error2
                  dirty := True -- will force save in the new format
               else
                  error := "#(1), #(2)" # error # error2
               end
            end
         else
            error := once "unknown vault format: #(1)" # format
         end
         if error.is_empty then
            log.info.put_line(once "Vault is open")
            if data.is_empty then
               -- new or empty vault, will force save
               dirty := True
            end
         else
            log.error.put_line(once "VAULT NOT OPEN! #(1)" # error)
         end
         bzero(master)
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

   for_each_key (action: PROCEDURE[TUPLE[KEY]])
      require
         is_open
         action /= Void
      do
         data.for_each(agent (a: PROCEDURE[TUPLE[KEY]]; k: KEY)
            do
               if not k.is_deleted then
                  a.call([k])
               end
            end(action, ?))
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
      do
         inspect
            format
         when "legacy" then
            Result := save_with(Legacy_file_provider())
         when "json" then
            Result := save_with(Json_file_provider())
         else
            Result := once "unknown vault format: #(1)" # format
         end
      ensure
         Result /= Void
         Result.is_empty = not dirty
      end

   set_random (a_name, a_recipe: STRING; a_private: BOOLEAN): ABSTRACT_STRING
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
            Result := set(a_name, pass_, a_private)
         end
      ensure
         Result /= Void
         Result.is_empty implies dirty
      end

   set (a_name, a_pass: STRING; a_private: BOOLEAN): ABSTRACT_STRING
      require
         is_open
         a_name /= Void
         a_pass /= Void
      local
         key: KEY
      do
         key := data.reference_at(a_name.intern)
         if key = Void then
            create key.new(a_name, a_pass, a_private)
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

   property (key_name, a_property: STRING): FIXED_STRING
      require
         key_name /= Void
         a_property /= Void
      local
         key: KEY
      do
         key := data.reference_at(key_name.intern)
         if key /= Void and then not key.is_deleted then
            inspect
               a_property
            when "username" then
               Result := key.username
            when "url" then
               Result := key.url
            end
         end
      end

   set_property (key_name, a_property, value: STRING): ABSTRACT_STRING
      require
         key_name /= Void
         a_property /= Void
         value /= Void
      local
         key: KEY
      do
         key := data.reference_at(key_name.intern)
         if key /= Void and then not key.is_deleted then
            Result := once ""
            inspect
               a_property
            when "username" then
               key.username := value
               dirty := True
            when "url" then
               key.url := value
               dirty := True
            when "tag" then
               if value.split.count = 1 and then value.split.first.is_equal(value) then
                  key.add_tag(value)
                  dirty := True
               else
                  Result := once "Invalid split tag: '#(1)'" # value
               end
            else
               Result := once "Invalid property"
            end
         else
            Result := once "Unknown key"
         end
      end

   unset_property (key_name, a_property, value: STRING): ABSTRACT_STRING
      require
         key_name /= Void
         a_property /= Void
         value /= Void
      local
         key: KEY
      do
         key := data.reference_at(key_name.intern)
         if key /= Void and then not key.is_deleted then
            Result := once ""
            inspect
               a_property
            when "username" then
               key.username := Void
               dirty := True
            when "url" then
               key.url := Void
               dirty := True
            when "tag" then
               if key.has_tag(value) then
                  key.del_tag(value)
               end
               dirty := True
            else
               Result := once "Invalid property"
            end
         else
            Result := once "Unknown key"
         end
      end

   tags: TRAVERSABLE[FIXED_STRING]
      local
         tagset: AVL_SET[FIXED_STRING]
      do
         create tagset.make
         data.for_each_item(agent (key: KEY; ts: SET[FIXED_STRING])
                               do
                                  if not key.is_deleted then
                                     key.tags.for_each(agent (tag: FIXED_STRING; t: SET[FIXED_STRING])
                                                          do
                                                             t.fast_add(tag)
                                                          end (?, ts))
                                  end
                               end (?, tagset))
         Result := tagset
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
   inout: VAULT_IO

feature {} -- Vault formats handling
   open_with (master: STRING; file_provider: FUNCTION[TUPLE, VAULT_FILE]): ABSTRACT_STRING
      require
         master /= Void
         not is_open
         file_provider /= Void
      local
         file: VAULT_FILE
      do
         inout := io_provider.item([master])
         if inout = Void then
            Result := once "no io provided"
         elseif not inout.exists then
            Result := once ""
            dirty := True
         else
            file := file_provider.item([])
            if file = Void then
               Result := once "no file provided"
            else
               Result := file.load(data, inout)
               log.trace.put_line("Vault found #(1) #(2)" # data.count.out # (if data.count = 1 then "entry" else "entries" end))
            end
         end
      end

   save_with (file_provider: FUNCTION[TUPLE, VAULT_FILE]): ABSTRACT_STRING
      require
         is_open
         file_provider /= Void
      local
         file: VAULT_FILE
      do
         if dirty then
            file := file_provider.item([])
            Result := file.save(data, inout)
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

   Legacy_file_provider: LEGACY_FILE_PROVIDER
   Json_file_provider: JSON_FILE_PROVIDER

   format: FIXED_STRING
      once
         if has_conf(config_format) then
            Result := conf(config_format)
         else
            Result := "json".intern
         end
      end

   config_format: FIXED_STRING
      once
         Result := ("format").intern
      end

   configuration_section: STRING "vault"

invariant
   io_provider /= Void
   data /= Void
   data.for_all(agent (key: KEY; name: FIXED_STRING): BOOLEAN
      do
         Result := key /= Void and then name = key.name
      end(?, ?))
   not is_open implies data.is_empty

end -- class VAULT
