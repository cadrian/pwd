-- This file is part of pwdmgr.
-- Copyright (C) 2012 Cyril Adrian <cyril.adrian@gmail.com>
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
deferred class MESSAGE

insert
   VISITABLE
   JSON_HANDLER

feature {ANY}
   json: JSON_OBJECT

   type: STRING is
      do
         Result := string(once "type")
      end

   command: STRING is
      do
         Result := string(once "command")
      end

feature {}
   from_json (a_json: JSON_OBJECT) is
      require
         a_json /= Void
      do
         json := a_json
      ensure
         json = a_json
      end

   string (a_key: ABSTRACT_STRING): STRING is
      require
         a_key /= Void
      local
         json_value: JSON_STRING
      do
         json_value ::= json.members.reference_at(json_string(a_key))
         if json_value /= Void then
            Result := json_value.string.to_utf8
         end
      end

   json_string (a_string: ABSTRACT_STRING): JSON_STRING is
      require
         a_string /= Void
      local
         intern_string: FIXED_STRING
      do
         intern_string := a_string.intern
         Result := strings.reference_at(intern_string)
         if Result = Void then
            create Result.from_string(intern_string)
            strings.add(Result, intern_string)
         end
      end

   strings: HASHED_DICTIONARY[JSON_STRING, FIXED_STRING] is
      once
         create Result.make
      end

   json_boolean (bool: BOOLEAN): JSON_VALUE is
      do
         if bool then
            Result := json_true
         else
            Result := json_false
         end
      end

   json_true: JSON_TRUE is
      once
         create Result.make
      end

   json_false: JSON_FALSE is
      once
         create Result.make
      end

invariant
   json /= Void

end
