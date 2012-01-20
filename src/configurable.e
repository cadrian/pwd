-- This file is part of pwdmgr.
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
            specific_section := generating_type.intern
         end
         Result := configuration.get(specific_section, key)
      end

   has_conf (key: ABSTRACT_STRING): BOOLEAN is
      require
         key /= Void
      do
         Result := conf(key) /= Void
      end

feature {}
   configuration: CONFIGURATION
   specific_section: FIXED_STRING

end
