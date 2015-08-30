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
expanded class SOCKET

insert
   CONFIGURABLE
   LOGGING

feature {ANY}
   port: INTEGER
      local
         conf_: FIXED_STRING
      do
         Result := 4793
         if has_conf(once "port") then
            conf_ := conf(once "port")
            if conf_ /= Void and then conf_.is_integer then
               Result := conf_.to_integer
            end
         end
      end

end -- class SOCKET
