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
class ENVIRONMENT_IMPL

inherit
   ENVIRONMENT_DEF

feature {ENVIRONMENT}
   variable (name: ABSTRACT_STRING): STRING
      do
         Result := system.get_environment_variable(name.out)
      end

   set_variable (name, value: ABSTRACT_STRING)
      do
         system.set_environment_variable(name.out, value.out)
      end

feature {}
   system: SYSTEM

end -- class ENVIRONMENT_IMPL
