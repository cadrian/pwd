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
class QUERY_MERGE

inherit
   MESSAGE

create {ANY}
   make, from_json

feature {ANY}
   accept (visitor: VISITOR) is
      local
         v: QUERY_VISITOR
      do
         v ::= visitor
         v.visit_merge(Current)
      end

feature {ANY}
   vault: STRING is
      do
         Result := string(once "vault")
      end

   master: STRING is
      do
         Result := string(once "master")
      end

feature {}
   make (a_vault, a_master: STRING) is
      do
         create json.make({HASHED_DICTIONARY[JSON_VALUE, JSON_STRING] <<
                           json_string(once "merge"), json_string(once "type");
                           json_string(once "query"), json_string(once "command");
                           create {JSON_STRING}.from_string(a_vault), json_string(once "vault");
                           create {JSON_STRING}.from_string(a_master), json_string(once "master");
                           >>})
      end

end
