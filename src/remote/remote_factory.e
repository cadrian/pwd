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
expanded class REMOTE_FACTORY

insert
   CONFIGURABLE

feature {ANY}
   new_remote (a_specific_section: ABSTRACT_STRING; a_client: CLIENT): REMOTE is
      require
         a_client /= Void
      local
         section: FIXED_STRING
      do
         if a_specific_section = Void or else a_specific_section.is_empty then
            -- no remote
         else
            specific_section := a_specific_section.intern
            section := conf(config_key_remote_method)
            if section = Void or else section.is_empty then
               -- no remote
            else
               inspect
                  section.out
               when "curl" then
                  create {CURL} Result.make(a_specific_section, a_client)
               when "scp" then
                  create {SCP} Result.make(a_specific_section)
               else
                  -- no remote
               end
            end
         end
      end

   config_key_remote_method: FIXED_STRING is
      once
         Result := "remote.method".intern
      end

end
