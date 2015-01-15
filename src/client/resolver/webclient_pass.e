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
         when "pass" then
            Result := pass
         else
            Result := Precursor(key)
         end
      end

feature {ANY}
   out_in_tagged_out_memory
      do
         tagged_out_memory.append(once "{WEBCLIENT_PASS}")
      end

feature {}
   pass: ABSTRACT_STRING

   make (a_pass: like pass; a_auth_token: FIXED_STRING; a_webclient: like webclient; a_error: like error)
      require
         a_pass /= Void
         a_auth_token /= Void
         a_webclient /= Void
         a_error /= Void
      do
         pass := a_pass
         auth_token := a_auth_token
         resolver_make(a_webclient, a_error)
      ensure
         pass = a_pass
         auth_token = a_auth_token
         webclient = a_webclient
         error = a_error
      end

invariant
   pass /= Void

end -- class WEBCLIENT_PASS
