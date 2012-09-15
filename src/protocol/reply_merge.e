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
class REPLY_MERGE

inherit
   MESSAGE

create {ANY}
   make, from_json

feature {ANY}
   accept (visitor: VISITOR) is
      local
         v: REPLY_VISITOR
      do
         v ::= visitor
         v.visit_merge(Current)
      end

feature {ANY}
   error: STRING is
      do
         Result := string(once "error")
      end

   vault: STRING is
      do
         Result := string(once "vault")
      end

feature {}
   make (a_error: ABSTRACT_STRING; a_vault: STRING) is
      require
         a_error /= Void
         a_vault /= Void
      do
         create json.make({HASHED_DICTIONARY[JSON_VALUE, JSON_STRING] <<
                           json_string(once "merge"), json_string(once "type");
                           json_string(once "reply"), json_string(once "command");
                           json_string(a_error), json_string(once "error");
                           create {JSON_STRING}.from_string(a_vault), json_string(once "vault");
                           >>})
      end

end
