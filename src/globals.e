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
deferred class GLOBALS

insert
   CONFIGURABLE
   LOGGING

feature {}
   shared: SHARED

   command_name: FIXED_STRING is
      local
         args: ARGUMENTS
      once
         Result := args.command_name.intern
      end

   make is
      local
         logconf: LOG_CONFIGURATION
         config: STRING_INPUT_STREAM
      do
         preload

         create config.from_string(("[
                                     log configuration

                                     root #(1)

                                     output
                                        default is
                                           file "#(2)"
                                           rotated each day keeping 3
                                        end

                                     logger
                                        #(1) is
                                           output default
                                           level info
                                        end

                                     end

                                                           ]"
                                     # generating_type # shared.log_file(generating_type.as_lower)
                                     ).out)

         logconf.load(config, Void, Void, agent main)
      end

   preload is
      deferred
      end

   main is
      deferred
      end

end
