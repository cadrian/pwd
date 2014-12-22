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
class WEBCLIENT_PASS

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
         when "pass" then
            Result := pass
         else
            error()
         end
      end

   while (key: STRING): BOOLEAN
      do
         error()
      end

feature {}
   error: PROCEDURE[TUPLE]
   pass: ABSTRACT_STRING

   make (a_pass: like pass; a_error: like error)
      require
         a_pass /= Void
         a_error /= Void
      do
         pass := a_pass
         error := a_error
      ensure
         pass = a_pass
         error = a_error
      end

invariant
   pass /= Void
   error /= Void

end -- class WEBCLIENT_PASS
