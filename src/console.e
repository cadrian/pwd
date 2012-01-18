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

feature {}
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
            io.put_string(once "[
                                Known commands:

                                add <key> [pass]   Add a new password. Needs at least a key.
                                                   If the password is not specified it is randomly generated.
                                                   If the password already exists it is changed.

                                rem <key>          Removes the password corresponding to the given key.

                                list               List the known passwords (show only the keys).

                                save               Save the password vault upto the server.

                                load               Replace the local vault with the server's version.

                                merge              Load the server version and compare to the local one.
                                                   Keep the most recent keys and save the merged version
                                                   back to the server.

                                master             Change the master password.

                                help               Show this screen :-)

                                Any other "command" is understood as a key.
                                In that case the password is stored in the clipboard.

                                ]")
         else
            io.put_line(once "Command <#(1)> not recognized." # io.last_string)
         end
      end

end
