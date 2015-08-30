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
class REPLY_LIST

inherit
   MESSAGE

create {ANY}
   make, from_json

feature {ANY}
   accept (visitor: VISITOR)
      local
         v: REPLY_VISITOR
      do
         v ::= visitor
         v.visit_list(Current)
      end

feature {ANY}
   error: STRING
      do
         Result := string(once "error")
      end

   for_each_name (action: PROCEDURE[TUPLE[STRING]])
      require
         action /= Void
      local
         array: JSON_ARRAY; str: JSON_STRING; i: INTEGER
      do
         array ::= json.members.reference_at(json_string(once "names"))
         from
            i := array.lower
         until
            i > array.upper
         loop
            str ::= array.item(i)
            action.call([str.string.to_utf8])
            i := i + 1
         end
      end

   count_names: INTEGER
      local
         array: JSON_ARRAY
      do
         array ::= json.members.reference_at(json_string(once "names"))
         Result := array.count
      end

feature {}
   make (a_error: ABSTRACT_STRING; a_names: COLLECTION[FIXED_STRING])
      require
         a_error /= Void
         a_names /= Void
      local
         json_names: FAST_ARRAY[JSON_STRING]
      do
         create json_names.with_capacity(a_names.count)
         create json.make({HASHED_DICTIONARY[JSON_VALUE, JSON_STRING] << json_string(once "reply"), json_string(once "type");
                                                                         json_string(once "list"), json_string(once "command");
                                                                         json_string(a_error), json_string(once "error");
                                                                         create {JSON_ARRAY}.make(json_names), json_string(once "names") >> })

         a_names.for_each(agent (a: FAST_ARRAY[JSON_STRING]; n: FIXED_STRING)
            do
               a.add_last(create {JSON_STRING}.from_string(n))
            end(json_names, ?))
      end

end -- class REPLY_LIST
