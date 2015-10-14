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
deferred class ABSTRACT_TEST_WEBCLIENT

insert
   EIFFELTEST_TOOLS

feature {}
   client: WEBCLIENT

   call_cgi (method, path: STRING; server_commands: STRING): STRING
      local
         system: SYSTEM; tfw: TEXT_FILE_WRITE; pf: PROCESS_FACTORY; p: PROCESS
         cgi_io: CGI_IO
         bd: BASIC_DIRECTORY; home: ABSTRACT_STRING
      do
         Result := ""

         if server_commands /= Void then
            create tfw.connect_to("webclient.conf/run/server.out")
            if tfw.is_connected then
               tfw.put_string(server_commands)
               tfw.disconnect
            end
            pf.set_direct_input(True)
            pf.set_direct_output(True)
            pf.set_direct_error(True)
            p := pf.execute_command_line("webclient.conf/exe/server")
         end


         home := "#(1)/webclient.conf" # bd.current_working_directory
         system.set_environment_variable("XDG_CONFIG_HOME", home.out)
         system.set_environment_variable("XDG_CACHE_HOME", ("#(1)/run" # home).out)
         system.set_environment_variable("XDG_RUNTIME_DIR", ("#(1)/run" # home).out)
         system.set_environment_variable("XDG_CONFIG_DIRS", home.out)
         system.set_environment_variable("XDG_DATA_HOME", home.out)
         system.set_environment_variable("REQUEST_METHOD", method)
         system.set_environment_variable("REMOTE_USER", "testuser")
         system.set_environment_variable("PATH_INFO", path)
         system.set_environment_variable("SERVER_NAME", "testserver")
         system.set_environment_variable("SERVER_PORT", "443")
         system.set_environment_variable("SERVER_PROTOCOL", "HTTP/1.1")
         system.set_environment_variable("SERVER_SOFTWARE", "eiffeltest")
         system.set_environment_variable("HTTPS", "on")
         system.set_environment_variable("HTTP_HOST", "test.server.net:8943")

         cgi_io.set_output(create {STRING_OUTPUT_STREAM}.connect_to(Result))

         create client.make
         if server_commands /= Void then
            p.wait
         end

         sedb_breakpoint
      end

   read_file (file: STRING): STRING
      local
         tfr: TEXT_FILE_READ
      do
         create tfr.connect_to(file)
         if tfr.is_connected then
            from
               Result := ""
               tfr.read_line
            until
               tfr.end_of_input
            loop
               Result.append(tfr.last_string)
               Result.extend('%N')
               tfr.read_line
            end
            Result.append(tfr.last_string)
            tfr.disconnect
         end
      end

end -- class ABSTRACT_TEST_WEBCLIENT
