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
deferred class GLOBALS

insert
   CONFIGURABLE
   LOGGING

feature {}
   shared: SHARED

   command_name: FIXED_STRING is
      once
         Result := configuration.command_name.intern
      end

   log_file: FIXED_STRING is
      once
         Result := shared.log_file(generating_type.as_lower)
      end

   make is
      local
         logconf: LOG_CONFIGURATION
         config: STRING_INPUT_STREAM
      do
         preload
         ensure_directory_of(shared.server_fifo)
         ensure_directory_of(shared.vault_file)
         ensure_directory_of(("#(1)/XXXXXX" # shared.tmp_dir).intern)
         ensure_directory_of(log_file)

         create config.from_string(("[
                                     log configuration

                                     root #(1)

                                     output
                                        default is
                                           file "#(2)"
                                           rotated each day keeping 3
                                           format "(@t) @C #(3) - @m%N"
                                        end

                                     logger
                                        #(1) is
                                           output default
                                           level info
                                        end

                                     end

                                     ]"
                                       # generating_type
                                       # log_file
                                       # command_name
                                     ).out)

         logconf.load(config, Void, Void, agent start_main)
      end

   ensure_directory_of (file: FIXED_STRING) is
      local
         dir: FIXED_STRING; i: INTEGER
         ft: FILE_TOOLS; bd: BASIC_DIRECTORY
      do
         i := file.last_index_of('/')
         if file.valid_index(i) and then i > file.lower then
            dir := file.substring(file.lower, i - 1)
            if ft.is_directory(dir) then
               -- OK
            elseif ft.file_exists(dir) then
               std_error.put_line("File exists and is not a directory: #(1)" # dir)
               die_with_code(1)
            else
               ensure_directory_of(dir)
               if not bd.create_new_directory(dir) then
                  std_error.put_line("Could not create directory: #(1)" # dir)
                  die_with_code(1)
               end
            end
         end
      end

   preload is
      deferred
      end

   start_main is
      do
         log.info.put_line("[
                            **************** STARTUP ****************
                            Configuration file:  #(1)
                            Server fifo:         #(2)
                            Vault is:            #(3)
                            Temporary directory: #(4)
                            Log file:            #(5)

                            ]"
                           # configuration.filename
                           # shared.server_fifo
                           # shared.vault_file
                           # shared.tmp_dir
                           # log_file)

         main

         log.info.put_line("**************** SHUTDOWN ****************")
      end

   main is
      deferred
      end

end
