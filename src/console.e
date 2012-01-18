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

   read_command is
      do
         io.put_string(once "%N[33mReady.[0m%N[1;32m>[0m ")
         io.flush
         io.read_line
         io.last_string.split_in(command)
      end

   run_command is
      require
         not command.is_empty
      local
         cmd: STRING
      do
         cmd := command.first
         command.remove_first
         inspect
            cmd
         when "help" then
            run_help
         else

         end
      end

feature {} -- commands
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
                    Otherwise the key is generated and stored in the clipboard.

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

end
