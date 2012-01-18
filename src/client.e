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
deferred class CLIENT

insert
   PROCESS_FACTORY
   ARGUMENTS
      undefine
         default_create
      end
   FILE_TOOLS
      undefine
         default_create
      end

feature {}
   fifo: FIFO

   server_fifo: FIXED_STRING
   vault: FIXED_STRING

   check_server is
      do
         if not fifo.exists(server_fifo) then
            start_server
            send_password
         end
      end

   start_server is
      require
         not fifo.exists(server_fifo)
      local
         proc: PROCESS
      do
         proc := execute_command_line((once "daemon #(1) #(2)" # server_fifo # vault).out)
         if proc.is_connected then
            proc.wait
            fifo.wait_for(server_fifo)
         end
      ensure
         fifo.exists(server_fifo)
      end

   send_password is
      require
         fifo.exists(server_fifo)
      local
         proc: PROCESS; pass: STRING
      do
         proc := execute(once "zenity", zenity_args)
         if proc.is_connected then
            proc.output.read_line
            pass := proc.output.last_string
            proc.wait
         end

         send(once "master #(1)" # pass)
      end

   zenity_args: FAST_ARRAY[STRING] is
      once
         Result := {FAST_ARRAY[STRING] <<
                                         "--entry",
                                         "--hide-text",
                                         "--title=Password",
                                         "--text=Please enter your master key to open the password vault"
                                       >> }
      end

   send (string: ABSTRACT_STRING) is
      require
         fifo.exists(server_fifo)
         string /= Void
      local
         tfw: TEXT_FILE_WRITE
      do
         create tfw.connect_to(server_fifo)
         if tfw.is_connected then
            tfw.put_string(string)
            tfw.disconnect
         end
      end

   xclip (string: ABSTRACT_STRING) is
      require
         string /= Void
      do
         xclipboards.do_all(agent xclip_select(string, ?))
      end

   xclip_select (string: ABSTRACT_STRING; selection: STRING) is
      local
         proc: PROCESS
      do
         proc := execute_command_line((once "xclip -selection #(1) -loops 3" # selection).out)
         if proc.is_connected then
            proc.input.put_line(string)
            proc.input.disconnect
            proc.wait
         end
      end

   xclipboards: FAST_ARRAY[STRING] is
      once
         Result := {FAST_ARRAY[STRING] << "primary", "clipboard" >>}
      end

invariant
   server_fifo /= Void
   vault /= Void

end
