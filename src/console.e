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
class CONSOLE

inherit
   CLIENT

create {}
   main

feature {} -- the CLIENT interface
   stop: BOOLEAN

   run is
      do
         from
            stop := False
            io.put_string(once "[
                                [1;32mWelcome to the pwdmgr administration console![0m

                                Type help for details on available options.
                                Just hit <enter> to exit.

                                ]")
         until
            stop
         loop
            read_command
            if command.is_empty then
               stop := True
            else
               run_command
            end
         end
      end

   check_argument_count: BOOLEAN is
      do
         Result := argument_count = 2 -- no extra arg
      end

   extra_args: STRING is "" -- no extra arg

feature {} -- command management
   command: RING_ARRAY[STRING] is
      once
         create Result.with_capacity(16, 0)
      end

   data: RING_ARRAY[STRING] is
      once
         create Result.with_capacity(16, 0)
      end

   read_command is
      do
         command.clear_count
         io.put_string(once "%N[33mReady.[0m%N[1;32m>[0m ")
         io.flush
         io.read_line
         io.last_string.split_in(command)
      end

   run_command is
      require
         not command.is_empty
         not fifo.exists(client_fifo)
      local
         cmd: STRING
      do
         cmd := command.first
         command.remove_first
         inspect
            cmd
         when "add" then
            run_add
         when "rem" then
            run_rem
         when "list" then
            run_list
         when "save" then
            run_save
         when "load" then
            run_load
         when "merge" then
            run_merge
         when "master" then
            io.put_line(once "not yet implemented.")
         when "help" then
            run_help
         else
            command.add_first(cmd) -- yes, add it again... it's a ring array so no harm done
            run_get
         end
      ensure
         not fifo.exists(client_fifo)
      end

feature {} -- commands
   get_data (cmd: ABSTRACT_STRING; action: PROCEDURE[TUPLE[INPUT_STREAM]]) is
      require
         not fifo.exists(client_fifo)
      local
         tfr: TEXT_FILE_READ
      do
         fifo.make(client_fifo)
         send(cmd)
         fifo.wait_for(client_fifo)
         create tfr.connect_to(client_fifo)
         if tfr.is_connected then
            action.call([tfr])
            tfr.disconnect
            delete(client_fifo)
         end
      ensure
         not fifo.exists(client_fifo)
      end

   run_get
         -- get key
      do
         get_data(once "get #(1) #(2)" # client_fifo # command.first,
                  agent (stream: INPUT_STREAM) is
                     do
                        stream.read_line
                        if not stream.end_of_input then
                           data.clear_count
                           stream.last_string.split_in(data)
                           if data.count = 2 then
                              xclip(data.last)
                           else
                              check data.count = 1 end
                              io.put_line(once "[1mUnknown password[0m")
                           end
                        end
                     end)
      end

   run_add is
         -- add key
      do
         send_save
      end

   run_rem is
         -- remove key
      do
         send_save
      end

   run_list is
         -- list known keys
      do
         get_data(once "list #(1)" # client_fifo,
                  agent (stream: INPUT_STREAM) is
                     local
                        str: STRING_OUTPUT_STREAM
                     do
                        create str.make
                        splice(stream, str)
                        less(str.to_string)
                     end)
      end

   run_save is
         -- save to remote
      do
         send_save
      end

   run_load is
         -- load from remote
      do
         send_save
      end

   run_merge is
         -- merge from remote
      do
         send_save
      end

   run_help is
      do
         less(once "[
                    [1;32mKnown commands[0m

                    [33madd <key> [pass][0m   Add a new password. Needs at least a key.
                                       If the password is not specified it is randomly generated.
                                       If the password already exists it is changed.
                                       In all cases the password is stored in the clipboard.

                    [33mrem <key>[0m          Removes the password corresponding to the given key.

                    [33mlist[0m               List the known passwords (show only the keys).

                    [33msave[0m               Save the password vault upto the server.

                    [33mload[0m               Replace the local vault with the server's version.

                    [33mmerge[0m              Load the server version and compare to the local one.
                                       Keep the most recent keys and save the merged version
                                       back to the server.

                    [33mmaster[0m             Change the master password. [1m(not yet implemented)[0m

                    [33mhelp[0m               Show this screen :-)

                    Any other input is understood as a password request using the given key.
                    If that key exists the password is stored in the clipboard.

                    ]")
      end

feature {} -- helpers
   less (string: ABSTRACT_STRING) is
      local
         proc: PROCESS
      do
         direct_output := True
         proc := execute_command_line("less -R")
         if proc.is_connected then
            proc.input.put_string(string)
            proc.input.flush
            proc.input.disconnect
            proc.wait
         end
      end

   splice (input: INPUT_STREAM; output: OUTPUT_STREAM) is
      require
         input.is_connected
         output.is_connected
      do
         from
            input.read_line
         until
            input.end_of_input or else input.last_string.is_empty
         loop
            output.put_line(input.last_string)
            input.read_line
         end
         output.put_string(input.last_string)
         output.flush
      end

end
