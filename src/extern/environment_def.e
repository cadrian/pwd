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
deferred class ENVIRONMENT_DEF

inherit
   TESTABLE

feature {ENVIRONMENT}
   variable (name: ABSTRACT_STRING): STRING
      require
         name /= Void
      deferred
      end

   set_variable (name, value: ABSTRACT_STRING)
      require
         name /= Void
         value /= Void
      deferred
      end

end -- class ENVIRONMENT_DEF
