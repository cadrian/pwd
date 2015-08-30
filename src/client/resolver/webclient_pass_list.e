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
class WEBCLIENT_PASS_LIST

inherit
   WEBCLIENT_RESOLVER
      rename
         make as resolver_make
      redefine
         item, while
      end

create {WEBCLIENT}
   make

feature {TEMPLATE_INPUT_STREAM}
   item (key: STRING): ABSTRACT_STRING
      do
         inspect
            key
         when "path" then
            Result := paths.item(index)
         when "name" then
            Result := names.item(index)
         when "form_token_name" then
            Result := form_token_name
         when "auth_token" then
            Result := auth_token
         else
            Result := Precursor(key)
         end
      end

   while (key: STRING): BOOLEAN
      do
         inspect
            key
         when "pass" then
            index := index + 1
            Result := paths.valid_index(index)
         else
            Result := Precursor(key)
         end
      end

feature {ANY}
   out_in_tagged_out_memory
      do
         tagged_out_memory.append(once "{WEBCLIENT_PASS_LIST count=")
         paths.count.append_in(tagged_out_memory)
         tagged_out_memory.extend('}')
      end

feature {}
   paths: ARRAY[ABSTRACT_STRING]
   names: ARRAY[ABSTRACT_STRING]
   index: INTEGER

   make (a_list: REPLY_LIST; a_auth_token: FIXED_STRING; a_webclient: like webclient; a_error: like error)
      require
         a_list /= Void
         a_auth_token /= Void
         a_webclient /= Void
         a_error /= Void
      do
         auth_token := a_auth_token
         resolver_make(a_webclient, a_error)
         create paths.with_capacity(a_list.count_names, 1)
         create names.with_capacity(a_list.count_names, 1)
         a_list.for_each_name(agent (root: ABSTRACT_STRING; name: STRING)
                              do
                                 if root /= Void then
                                    paths.add_last("#(1)/pass/#(2)" # root # name)
                                 else
                                    paths.add_last("/pass/#(1)" # name)
                                 end
                                 names.add_last(name)
                              end(webclient.root, ?))
      ensure
         auth_token = a_auth_token
         webclient = a_webclient
         error = a_error
         paths.count = a_list.count_names
         names.count = a_list.count_names
      end

invariant
   paths.count = names.count

end -- class WEBCLIENT_PASS_LIST
