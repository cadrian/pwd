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
class WEBCLIENT_PASS

inherit
   WEBCLIENT_RESOLVER
      rename
         make as resolver_make
      redefine
         item, while, start, break
      end

create {WEBCLIENT}
   make

feature {TEMPLATE_INPUT_STREAM}
   item (name: STRING): ABSTRACT_STRING
      local
         key_loops: FAST_ARRAY[INTEGER]
      do
         inspect
            name
         when "key" then
            Result := name
         when "pass" then
            Result := pass
         when "username" then
            Result := username
         when "url" then
            Result := url
         when "tag" then
            key_loops := loops.reference_at(once "tags")
            if key_loops /= Void then
               Result := tags.item(key_loops.last)
            end
         else
            Result := Precursor(name)
         end
      end

   start (name: STRING): BOOLEAN
      local
         key_loops: FAST_ARRAY[INTEGER]
      do
         key_loops := loops.reference_at(name)
         if key_loops = Void then
            create key_loops.make(0)
            loops.add(key_loops, name.twin)
         end
         inspect
            name
         when "username" then
            if not username.is_empty then
               key_loops.add_last(0)
               Result := True
            end
         when "url" then
            if not url.is_empty then
               key_loops.add_last(0)
               Result := True
            end
         when "tags" then
            if not tags.is_empty then
               key_loops.add_last(tags.lower - 1)
               Result := True
            end
         else
            check not Result end
         end
      end

   while (name: STRING): BOOLEAN
      local
         key_loops: FAST_ARRAY[INTEGER]; value: INTEGER
      do
         key_loops := loops.reference_at(name)
         if key_loops /= Void and then not key_loops.is_empty then
            value := key_loops.last
            inspect
               name
            when "username", "url" then
               if value = 0 then
                  Result := True
                  key_loops.put(1, 0)
               end
            when "tags" then
               if value < tags.upper then
                  Result := True
                  key_loops.put(value + 1, key_loops.upper)
               end
            else
               Result := Precursor(name)
            end
         else
            Result := Precursor(name)
         end
      end

   break (name: STRING)
      local
         key_loops: FAST_ARRAY[INTEGER]
      do
         key_loops := loops.reference_at(name)
         check
            key_loops /= Void and then not key_loops.is_empty
         end
         key_loops.remove_last
      end

feature {ANY}
   out_in_tagged_out_memory
      do
         tagged_out_memory.append(once "{WEBCLIENT_PASS}")
      end

feature {}
   make (a_key: like key; a_pass: like pass; a_username: like username; a_url: like url; a_tags: like tags; a_auth_token: FIXED_STRING; a_webclient: like webclient; a_error: like error)
      require
         a_key /= Void
         a_pass /= Void
         a_username /= Void
         a_url /= Void
         a_tags /= Void
         a_auth_token /= Void
         a_webclient /= Void
         a_error /= Void
      do
         key := a_key
         pass := a_pass
         auth_token := a_auth_token
         create loops.make
         resolver_make(a_webclient, a_error)
      ensure
         key = a_key
         pass = a_pass
         username = a_username
         url = a_url
         tags = a_tags
         auth_token = a_auth_token
         webclient = a_webclient
         error = a_error
      end

   key, pass, username, url: ABSTRACT_STRING
   tags: INDEXABLE[ABSTRACT_STRING]
   loops: HASHED_DICTIONARY[FAST_ARRAY[INTEGER], STRING]

invariant
   key /= Void
   pass /= Void
   username /= Void
   url /= Void
   tags /= Void
   loops /= Void

end -- class WEBCLIENT_PASS
