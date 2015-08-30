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
expanded class REMOTE_FACTORY

insert
   CONFIGURABLE
   LOGGING

feature {ANY}
   load_remote (a_name: ABSTRACT_STRING; a_client: CLIENT): REMOTE
      require
         a_client /= Void
         not a_name.is_empty
      local
         method: FIXED_STRING
      do
         specific_config := configuration.specific(a_name.intern)
         method := conf(config_key_remote_method)
         if method /= Void and then not method.is_empty then
            Result := new_remote(a_name, method, a_client)
         end
      end

   new_remote (a_name, a_method: ABSTRACT_STRING; a_client: CLIENT): REMOTE
      require
         a_client /= Void
         not a_name.is_empty
         not a_method.is_empty
      do
         inspect
            a_method.out
         when "curl" then
            create {CURL} Result.make(a_name.intern, a_client)
         when "scp" then
            create {SCP} Result.make(a_name.intern)
         else
            log.warning.put_line(once "Unknown remote method: #(1)" # a_method)
         end
      end

   config_key_remote_method: FIXED_STRING
      once
         Result := ("method").intern
      end

end -- class REMOTE_FACTORY
