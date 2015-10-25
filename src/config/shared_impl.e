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
class SHARED_IMPL

inherit
   SHARED_DEF

insert
   CONFIGURABLE
   LOGGING

feature {SHARED}
   server_pidfile: FIXED_STRING
      once
         Result := ("#(1)/server_pid" # xdg.runtime_dir).intern
      end

   vault_file: FIXED_STRING
      once
         Result := ("#(1)/vault" # xdg.data_home).intern
      end

   log_file (tag: ABSTRACT_STRING): FIXED_STRING
      do
         Result := (once "#(1)/#(2).log" # xdg.cache_home # tag).intern
      end

   runtime_dir: FIXED_STRING
      once
         Result := xdg.runtime_dir
      end

   log_level: FIXED_STRING
      once
         Result := conf(config_log_level)
         if Result = Void then
            Result := ("info").intern
         end
      end

   default_recipe: FIXED_STRING
      once
         Result := conf(config_default_recipe)
         if Result = Void then
            Result := ("an+s+14ansanansaan").intern -- default is 16 chars long, with at least one alphanumeric and one symbol
         end
      end

   channel_method: FIXED_STRING
      once
         Result := conf(config_channel_method)
         if Result = Void then
            Result := ("fifo").intern -- default is named fifo
         end
      end

   master_command: FIXED_STRING
      once
         Result := conf(config_master_command)
         if Result = Void then
            Result := ("zenity").intern
         end
      end

   master_arguments: FIXED_STRING
      once
         Result := conf(config_master_arguments)
         if Result = Void then
            Result := ("--entry --hide-text --title=Password --text=%"#(1)%"").intern
         end
      end

feature {}
   xdg: XDG

   mandatory_key (key: FIXED_STRING): FIXED_STRING
      require
         key /= Void
      do
         Result := conf(key)
         if Result = Void then
            std_error.put_line(once "Missing [shared]#(1)" # key)
            sedb_breakpoint
            die_with_code(1)
         end
      ensure
         Result /= Void
      end

   config_log_level: FIXED_STRING
      once
         Result := ("log.level").intern
      end

   config_default_recipe: FIXED_STRING
      once
         Result := ("default_recipe").intern
      end

   config_channel_method: FIXED_STRING
      once
         Result := ("channel.method").intern
      end

   config_master_command: FIXED_STRING
      once
         Result := ("master.command").intern
      end

   config_master_arguments: FIXED_STRING
      once
         Result := ("master.arguments").intern
      end

end -- class SHARED
