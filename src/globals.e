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
deferred class GLOBALS

insert
   CONFIGURABLE
   LOGGING

feature {}
   shared: SHARED

   version: FIXED_STRING
      local
         v: VERSION
      do
         Result := v.version
      end

   command_name: FIXED_STRING
      once
         Result := configuration.command_name.intern
      end

   log_file: FIXED_STRING
      once
         Result := shared.log_file(generating_type.as_lower)
      end

   make
      local
         logconf: LOG_CONFIGURATION; config: STRING_INPUT_STREAM; config_string: ABSTRACT_STRING
      do
         preload
         config_string := "[
                           log configuration

                           root #(1)

                           output
                              default is
                                 file "#(2)"
                                 rotated each day keeping 3
                                 format "(@t) @C #(3):@I - @m%N"
                              end

                           logger
                              #(1) is
                                 output default
                                 level #(4)
                              end

                           end

                           ]" # generating_type # log_file # command_name # shared.log_level

         create config.from_string(config_string.out)

         logconf.load(config, Void, Void, agent start_main)
      end

   preload
      deferred
      end

   start_main
      do
         log.info.put_line("[
                            **************** STARTUP ****************
                            Main configuration file: #(1)
                            Server pid file:         #(2)
                            Vault is:                #(3)
                            Runtime directory:       #(4)
                            Log file:                #(5)

                            ]" # configuration.main_config.filename # shared.server_pidfile # shared.vault_file # shared.runtime_dir # log_file)
         main

         log.info.put_line("**************** SHUTDOWN ****************")
      end

   main
      deferred
      end

end -- class GLOBALS
