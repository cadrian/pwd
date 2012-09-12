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
expanded class SHARED

insert
   CONFIGURABLE
   LOGGING

feature {ANY}
   server_pidfile: FIXED_STRING is
      once
         Result := ("#(1)/server_pid" # xdg.runtime_dir).intern
         log.info.put_line(once "Server pid file: #(1)" # Result)
      end

   vault_file: FIXED_STRING is
      once
         Result := ("#(1)/vault" # xdg.data_home).intern
         log.info.put_line(once "Vault file: #(1)" # Result)
      end

   log_file (tag: ABSTRACT_STRING): FIXED_STRING is
      require
         tag /= Void
      do
         Result := (once "#(1)/#(2).log" # xdg.cache_home # tag).intern
         log.info.put_line(once "Logging file: #(1)" # Result)
      end

   runtime_dir: FIXED_STRING is
      once
         Result := xdg.runtime_dir
         log.info.put_line(once "XDG runtime directory: #(1)" # Result)
      end

   log_level: FIXED_STRING is
      once
         Result := conf(config_log_level)
         if Result = Void then
            Result := "info".intern
         end
         log.info.put_line(once "Logging level: #(1)" # Result)
      end

   default_recipe: FIXED_STRING is
      once
         Result := conf(config_default_recipe)
         if Result = Void then
            Result := "an+s+14ansanansaan".intern -- default is 16 chars long, with at least one alphanumeric and one symbol
         end
         log.info.put_line(once "Default recipe: #(1)" # Result)
      end

   channel_method: FIXED_STRING is
      once
         Result := conf(config_channel_method)
         if Result = Void then
            Result := "fifo".intern -- default is named fifo
         end
         log.info.put_line(once "Channel method: #(1)" # Result)
      end

feature {}
   xdg: XDG

   mandatory_key (key: FIXED_STRING): FIXED_STRING is
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

   config_log_level: FIXED_STRING is
      once
         Result := "log.level".intern
      end

   config_default_recipe: FIXED_STRING is
      once
         Result := "default_recipe".intern
      end

   config_channel_method: FIXED_STRING is
      once
         Result := "channel.method".intern
      end

end
