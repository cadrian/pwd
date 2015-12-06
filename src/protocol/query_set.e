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
class QUERY_SET

inherit
   MESSAGE

create {ANY}
   make_random, make_given, from_json

feature {ANY}
   accept (visitor: VISITOR)
      local
         v: QUERY_VISITOR
      do
         v ::= visitor
         v.visit_set(Current)
      end

   clean
      local
         cleaner: JSON_CLEANER
         jv: JSON_VALUE
      do
         create cleaner
         jv := json.members.reference_at(json_string(once "pass"))
         if jv /= Void then
            jv.accept(cleaner)
         end
         json.members.reference_at(json_string(once "key")).accept(cleaner)
      end

feature {ANY}
   key: STRING then string(once "key") end
   recipe: STRING then string(once "recipe") end
   pass: STRING then string(once "pass") end
   private: BOOLEAN then boolean(once "private") end

feature {}
   make_random (a_key, a_recipe: ABSTRACT_STRING; a_private: BOOLEAN)
      require
         a_key /= Void
         a_recipe /= Void
      do
         create json.make({HASHED_DICTIONARY[JSON_VALUE, JSON_STRING] <<
            json_string(once "query"), json_string(once "type");
            json_string(once "set"), json_string(once "command");
            create {JSON_STRING}.from_string(a_key), json_string(once "key");
            create {JSON_STRING}.from_string(a_recipe), json_string(once "recipe");
            json_boolean(a_private), json_string(once "private")
         >> })
      end

   make_given (a_key, a_pass: STRING; a_private: BOOLEAN)
      require
         a_key /= Void
         a_pass /= Void
      do
         create json.make({HASHED_DICTIONARY[JSON_VALUE, JSON_STRING] <<
            json_string(once "query"), json_string(once "type");
            json_string(once "set"), json_string(once "command");
            create {JSON_STRING}.from_string(a_key), json_string(once "key");
            create {JSON_STRING}.from_string(a_pass), json_string(once "pass");
            json_boolean(a_private), json_string(once "private")
         >> })
      end

end -- class QUERY_SET
