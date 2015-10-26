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
expanded class ENVIRONMENT
   --
   -- A façade to the actual environment implementation
   --

insert
   TEST_FACADE[ENVIRONMENT_DEF]

feature {ANY}
   variable (name: ABSTRACT_STRING): STRING
      require
         name /= Void
      do
         Result := def.variable(name)
      end

   set_variable (name, value: ABSTRACT_STRING)
      require
         name /= Void
         value /= Void
      do
         def.set_variable(name, value)
      end

feature {}
   def_impl: ENVIRONMENT_IMPL
      once
         create Result
      end

end -- class ENVIRONMENT
