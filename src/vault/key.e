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

create {KEY_HANDLER}
   from_file

feature {ANY}
   name: FIXED_STRING
   pass: STRING
   username: FIXED_STRING
   url: FIXED_STRING

   tags: TRAVERSABLE[FIXED_STRING]
      do
         Result := tagset
      end

   is_private: BOOLEAN

   has_tag (tag: ABSTRACT_STRING): BOOLEAN
      require
         tag /= Void
      do
         Result := tagset.fast_has(tag.intern)
      end

feature {VAULT}
   add_tag (tag: ABSTRACT_STRING)
      require
         tag.split.count = 1 and then tag.split.first.is_equal(tag)
      do
         tagset.fast_add(tag.intern)
      ensure
         has_tag(tag)
      end

   del_tag (tag: ABSTRACT_STRING)
      require
         has_tag(tag)
      do
         tagset.fast_remove(tag.intern)
      end

   is_deleted: BOOLEAN
      do
         Result := del_count > add_count
      end

   set_pass (a_pass: STRING) assign pass
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

   set_username (a_username: ABSTRACT_STRING) assign username
      do
         if a_username = Void then
            username := Void
         else
            username := a_username.intern
         end
      ensure
         a_username = Void implies username = Void
         a_username /= Void implies username = a_username.intern
      end

   set_url (a_url: ABSTRACT_STRING) assign url
      do
         if a_url = Void then
            url := Void
         else
            url := a_url.intern
         end
      ensure
         a_url = Void implies url = Void
         a_url /= Void implies url = a_url.intern
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
         --| **** TODO: do we have to merge properties?
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
   new (a_name: ABSTRACT_STRING; a_pass: STRING; private: BOOLEAN)
      require
         a_name /= Void
         a_pass /= Void
      do
         from_file(a_name, a_pass, 0, 0, Void, private)
      ensure
         not is_deleted
      end

   from_file (a_name: ABSTRACT_STRING; a_pass: STRING; a_add_count, a_del_count: INTEGER; a_properties: MAP[ABSTRACT_STRING, FIXED_STRING]; private: BOOLEAN)
      require
         a_name /= Void
         a_pass /= Void
         a_add_count >= 0
         a_del_count >= 0
         a_properties /= Void implies a_properties.for_all(agent (v: ABSTRACT_STRING; k: FIXED_STRING): BOOLEAN then valid_properties.fast_has(k) end (?, ?))
      local
         v: ABSTRACT_STRING
      do
         name := a_name.intern
         pass := a_pass
         add_count := a_add_count
         del_count := a_del_count
         if a_properties = Void then
            create tagset.with_capacity(2)
         else
            v := a_properties.fast_reference_at(Property_username)
            if v /= Void then
               set_username(v)
            end
            v := a_properties.fast_reference_at(Property_url)
            if v /= Void then
               set_url(v)
            end
            v := a_properties.fast_reference_at(Property_tags)
            if v = Void then
               create tagset.with_capacity(2)
            else
               create tagset.with_capacity(1 + v.occurrences(' '))
               v.split.for_each(agent (tag: STRING) do add_tag(tag) end (?))
            end
         end
         is_private := private
      ensure
         name = a_name.intern
         pass = a_pass
         add_count = a_add_count
         del_count = a_del_count
         (a_properties /= Void and then a_properties.fast_has(Property_username)) implies username.is_equal(a_properties.fast_at(Property_username))
         (a_properties /= Void and then a_properties.fast_has(Property_url)) implies url.is_equal(a_properties.fast_at(Property_url))
         (a_properties /= Void and then a_properties.fast_has(Property_tags)) implies tagset.count = 1 + a_properties.fast_at(Property_tags).occurrences(' ')
         is_private = private
       end

feature {KEY, KEY_HANDLER}
   add_count: INTEGER
   del_count: INTEGER
   tagset: HASHED_SET[FIXED_STRING]

   Property_username: FIXED_STRING once then "username".intern end
   Property_url: FIXED_STRING once then "url".intern end
   Property_tags: FIXED_STRING once then "tags".intern end

   valid_properties: SET[FIXED_STRING]
      once
         Result := {HASHED_SET[FIXED_STRING] <<
            Property_username, Property_url, Property_tags
         >> }
      end

invariant
   pass /= Void
   tagset /= Void

end -- class KEY
