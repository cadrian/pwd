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
deferred class CONFIGURABLE

feature {}
   conf_no_eval (key: ABSTRACT_STRING): FIXED_STRING
      require
         key /= Void
      do
         check_specific
         Result := specific_config.get_no_eval(specific_section, key)
      end

   conf (key: ABSTRACT_STRING): FIXED_STRING
      require
         key /= Void
      do
         check_specific
         Result := specific_config.get(specific_section, key)
         debug
            if Result = Void then
               io.put_line("conf(%"#(1)%") = Void" # key)
            else
               io.put_line("conf(%"#(1)%") = %"#(2)%"" # key # Result)
            end
         end
      end

   has_conf (key: ABSTRACT_STRING): BOOLEAN
      require
         key /= Void
      do
         check_specific
         Result := specific_config.has(specific_section, key)
      end

feature {}
   configuration: CONFIGURATION
      once
         create Result
      end

   specific_section: FIXED_STRING

   specific_config: CONFIG_FILE

   check_specific
      local
         s: like configuration_section
      do
         if specific_section = Void then
            s := configuration_section
            if s /= Void then
               specific_section := s.intern
            end
         end
         if specific_config = Void then
            specific_config := configuration.main_config
         end
      ensure
         specific_section /= Void
         specific_config /= Void
      end

   configuration_section: ABSTRACT_STRING
         -- The name of the configuration section to user. May be Void.
      deferred
      end

end -- class CONFIGURABLE
