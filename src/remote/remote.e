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
deferred class REMOTE

insert
   CONFIGURABLE

feature {ANY}
   name: FIXED_STRING

   save (local_file: ABSTRACT_STRING) is
      require
         local_file /= Void
      deferred
      end

   load (local_file: ABSTRACT_STRING) is
      require
         local_file /= Void
      deferred
      end

feature {}
   processor: PROCESSOR

   specific_section_: FIXED_STRING is
      once
         Result := "remote".intern
      end

invariant
   name /= Void
   specific_section = specific_section_

end
