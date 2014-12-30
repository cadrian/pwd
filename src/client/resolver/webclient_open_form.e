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
class WEBCLIENT_OPEN_FORM

inherit
   WEBCLIENT_RESOLVER
      rename
         make as resolver_make
      redefine
         item
      end

create {WEBCLIENT}
   make

feature {TEMPLATE_INPUT_STREAM}
   item (key: STRING): ABSTRACT_STRING
      do
         inspect
            key
         when "form_token_name" then
            Result := form_token_name
         when "form_password_name" then
            Result := form_password_name
         when "auth_token" then
            Result := auth_token
         else
            Result := Precursor(key)
         end
      end

feature {ANY}
   out_in_tagged_out_memory
      do
         tagged_out_memory.append(once "{WEBCLIENT_OPEN_FORM}")
      end

feature {}
   auth_token: STRING

   make (a_auth_token: STRING; a_webclient: like webclient; a_error: like error)
      require
         a_auth_token /= Void
         a_webclient /= Void
         a_error /= Void
      do
         auth_token := a_auth_token
         resolver_make(a_webclient, a_error)
      ensure
         auth_token = a_auth_token
         webclient = a_webclient
         error = a_error
      end

invariant
   auth_token /= Void

end -- class WEBCLIENT_OPEN_FORM
