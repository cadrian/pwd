-- This file is part of pwd.
-- Copyright (C) 2012-2014 Cyril Adrian <cyril.adrian@gmail.com>
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
   TEMPLATE_RESOLVER

insert
   WEBCLIENT_GLOBALS

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
         else
            error()
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
            error()
         end
      end

feature {}
   error: PROCEDURE[TUPLE]
   paths: ARRAY[ABSTRACT_STRING]
   names: ARRAY[ABSTRACT_STRING]
   index: INTEGER

   make (a_script_name: ABSTRACT_STRING; a_list: REPLY_LIST; a_error: like error)
      require
         a_list /= Void
         a_error /= Void
      do
         create paths.with_capacity(a_list.count_names, 1)
         create names.with_capacity(a_list.count_names, 1)
         a_list.for_each_name(agent (name: STRING)
                              do
                                 if a_script_name /= Void then
                                    paths.add_last("#(1)/#(2)" # a_script_name # name)
                                 else
                                    paths.add_last(name)
                                 end
                                 names.add_last(name)
                              end(?))
         error := a_error
      ensure
         paths.count = a_list.count_names
         names.count = a_list.count_names
         error = a_error
      end

invariant
   paths.count = names.count
   error /= Void

end -- class WEBCLIENT_PASS_LIST
