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
expanded class SHARED

insert
   CONFIGURABLE
   LOGGING

feature {ANY}
   daemon_fifo: FIXED_STRING is
      do
         Result := conf(config_daemon_fifo)
      end

   vault_file: FIXED_STRING is
      do
         Result := conf(config_vault_file)
         if Result = Void then
            log.error.put_line(once "Could not find [shared]vault.file")
            die_with_code(1)
         end
      end

   log_file (tag: ABSTRACT_STRING): FIXED_STRING is
      require
         tag /= Void
      local
         logdir: FIXED_STRING
         processor: PROCESSOR
      do
         logdir := conf(config_log_dir)
         if logdir /= Void then
            Result := processor.split_arguments(once "#(1)/#(2).log" # logdir # tag).first.intern
         end
      end

feature {}
   config_daemon_fifo: FIXED_STRING is
      once
         Result := "daemon.fifo".intern
      end

   config_log_dir: FIXED_STRING is
      once
         Result := "log.dir".intern
      end

   config_vault_file: FIXED_STRING is
      once
         Result := "vault.file".intern
      end

end
