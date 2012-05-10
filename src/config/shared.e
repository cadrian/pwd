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
   server_fifo: FIXED_STRING is
      once
         Result := mandatory_key(config_server_fifo)
      end

   server_pidfile: FIXED_STRING is
      once
         Result := mandatory_key(config_server_pidfile)
      end

   vault_file: FIXED_STRING is
      once
         Result := mandatory_key(config_vault_file)
      end

   log_file (tag: ABSTRACT_STRING): FIXED_STRING is
      require
         tag /= Void
      do
         Result := (once "#(1)/#(2).log" # mandatory_key(config_log_dir) # tag).intern
      end

   tmp_dir: FIXED_STRING is
      once
         Result := mandatory_key(config_tmp_fifo_dir)
      end

   log_level: FIXED_STRING is
      once
         Result := conf(config_log_level)
         if Result = Void then
            Result := "info".intern
         end
      end

   default_recipe: FIXED_STRING is
      once
         Result := conf(config_default_recipe)
         if Result = Void then
            Result := "an+s+14ansanansaan".intern -- default is 16 chars long, with at least one alphanumeric and one symbol
         end
      end

   channel_method: FIXED_STRING is
      once
         Result := conf(config_channel_method)
         if Result = Void then
            Result := "fifo".intern -- default is named fifo
         end
      end

feature {}
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

   config_server_fifo: FIXED_STRING is
      once
         Result := "server.fifo".intern
      end

   config_server_pidfile: FIXED_STRING is
      once
         Result := "server.pidfile".intern
      end

   config_log_dir: FIXED_STRING is
      once
         Result := "log.dir".intern
      end

   config_log_level: FIXED_STRING is
      once
         Result := "log.level".intern
      end

   config_vault_file: FIXED_STRING is
      once
         Result := "vault.file".intern
      end

   config_tmp_fifo_dir: FIXED_STRING is
      once
         Result := "tmp.fifo.dir".intern
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
