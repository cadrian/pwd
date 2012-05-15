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
class CONFIGURATION

insert
   ARGUMENTS
      redefine
         default_create
      end

create {CONFIGURABLE}
   default_create

feature {ANY}
   main_config: CONFIG_FILE

   specific (name: ABSTRACT_STRING): CONFIG_FILE is
      do
         Result := config_map.fast_reference_at(name.intern)
         if Result = Void then
            Result := load_config(once "#(1).rc" # name, True)
            config_map.add(Result, name.intern)
         end
      ensure
         Result /= Void
      end

feature {ANY}
   parse_extra_conf (a_conf_file: ABSTRACT_STRING) is
      require
         a_conf_file /= Void
      do
         if main_config = Void then
            main_config := load_config(a_conf_file, False)
         end
      end

feature {}
   xdg: XDG

   default_create is
      do
         main_config := load_config(once "config.rc", False)
      end

   load_config (a_filename: ABSTRACT_STRING; allow_unknown: BOOLEAN): CONFIG_FILE is
      require
         a_filename /= Void
      local
         tfr: TEXT_FILE_READ
      do
         tfr := xdg.read_config(a_filename)
         if tfr /= Void then
            create Result.make(a_filename.intern, tfr)
            tfr.disconnect
         elseif allow_unknown then
            create Result.make(a_filename.intern, Void)
         end
      ensure
         allow_unknown implies Result /= Void
      end

   config_map: HASHED_DICTIONARY[CONFIG_FILE, FIXED_STRING] is
      once
         create Result.make
      end

invariant
   main_config /= Void

end
