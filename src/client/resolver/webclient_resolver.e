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
deferred class WEBCLIENT_RESOLVER

inherit
   TEMPLATE_RESOLVER
      undefine
         out_in_tagged_out_memory
      end

insert
   WEBCLIENT_GLOBALS
      undefine
         out_in_tagged_out_memory
      end

feature {TEMPLATE_INPUT_STREAM}
   item (key: STRING): ABSTRACT_STRING
      do
         inspect
            key
         when "root" then
            Result := webclient.root
         when "form_token_name" then
            Result := form_token_name
         when "auth_token" then
            Result := auth_token
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
   webclient: WEBCLIENT
   auth_token: STRING

   make (a_webclient: like webclient; a_error: like error)
      require
         a_webclient /= Void
         a_error /= Void
      do
         webclient := a_webclient
         error := a_error
      ensure
         webclient = a_webclient
         error = a_error
      end

invariant
   webclient /= Void
   error /= Void
   auth_token /= Void

end -- class WEBCLIENT_RESOLVER
