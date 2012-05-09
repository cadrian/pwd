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
expanded class CONFIGURABLE

feature {ANY}
   conf (key: ABSTRACT_STRING): FIXED_STRING is
      require
         key /= Void
      do
         if specific_section = Void then
            specific_section := generating_type.as_lower.intern
         end
         Result := eval(configuration.get(specific_section, key))
      end

   has_conf (key: ABSTRACT_STRING): BOOLEAN is
      require
         key /= Void
      do
         Result := conf(key) /= Void
      end

   conf_filename: FIXED_STRING is
      do
         Result := configuration.filename
      end

feature {}
   eval (string: ABSTRACT_STRING): FIXED_STRING is
         -- takes care of environment variables etc.
      local
         processor: PROCESSOR
      do
         if string /= Void then
            Result := processor.split_arguments(string).first.intern
         end
      end

feature {}
   configuration: CONFIGURATION is
      once
         create Result
      end

   specific_section: FIXED_STRING

end
