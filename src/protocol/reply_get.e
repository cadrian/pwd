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
class REPLY_GET

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
         v.visit_get(Current)
      end

   clean
      local
         cleaner: JSON_CLEANER
      do
         create cleaner
         json.members.reference_at(json_string(once "key")).accept(cleaner)
         json.members.reference_at(json_string(once "pass")).accept(cleaner)
         json.members.reference_at(json_string(once "username")).accept(cleaner)
         json.members.reference_at(json_string(once "url")).accept(cleaner)
         json.members.reference_at(json_string(once "tags")).accept(cleaner)
      end

   error: STRING
      do
         Result := string(once "error")
      end

   key: STRING
      do
         Result := string(once "key")
      end

   pass: STRING
      do
         Result := string(once "pass")
      end

   username: STRING
      do
         Result := string(once "username")
      end

   url: STRING
      do
         Result := string(once "url")
      end

   tags: FAST_ARRAY[STRING]
      local
         array: JSON_ARRAY; str: JSON_STRING; i: INTEGER
      do
         array ::= json.members.reference_at(json_string(once "tags"))
         create Result.with_capacity(array.count)
         from
            i := array.lower
         until
            i > array.upper
         loop
            str ::= array.item(i)
            Result.add_last(str.string.to_utf8)
            i := i + 1
         end
      end

feature {}
   make (a_error: ABSTRACT_STRING; a_key: ABSTRACT_STRING; a_pass: ABSTRACT_STRING; a_username: ABSTRACT_STRING; a_url: ABSTRACT_STRING; a_tags: TRAVERSABLE[ABSTRACT_STRING])
      require
         a_error /= Void
         a_key /= Void
         a_pass /= Void
         a_username /= Void
         a_url /= Void
         a_tags /= Void
      local
         json_tags: FAST_ARRAY[JSON_STRING]
      do
         create json.make({HASHED_DICTIONARY[JSON_VALUE, JSON_STRING] <<
            json_string(once "reply"), json_string(once "type");
            json_string(once "get"), json_string(once "command");
            json_string(a_error), json_string(once "error");
            create {JSON_STRING}.from_string(a_key), json_string(once "key");
            create {JSON_STRING}.from_string(a_pass), json_string(once "pass");
            create {JSON_STRING}.from_string(a_username), json_string(once "username");
            create {JSON_STRING}.from_string(a_url), json_string(once "url");
            create {JSON_ARRAY}.make(json_tags), json_string(once "tags")
         >> })

         a_tags.for_each(agent (tag: ABSTRACT_STRING)
            do
               json_tags.add_last(create {JSON_STRING}.from_string(tag))
            end (?))
      end

end -- class REPLY_GET
