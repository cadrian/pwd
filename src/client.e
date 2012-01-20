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
   ARGUMENTS
   FILE_TOOLS
   CONFIGURABLE

feature {}
   processor: PROCESSOR

   tmpdir: FIXED_STRING
   client_fifo: FIXED_STRING
   restart: BOOLEAN

   main is
      do
         if argument_count /= 4 then
            std_error.put_line("Usage: #(1) <server fifo> <vault> <log dir> <conf file>")
            die_with_code(1)
         end

         tmpdir := fifo.tmp
         if tmpdir = Void then
            std_error.put_line("#(1): could not create tmp directory!" # command_name)
            die_with_code(1)
         end

         client_fifo := ("#(1)/fifo" # tmpdir).intern
         server_fifo := argument(1).intern
         vault := argument(2).intern
         logdir := argument(3).intern

         from
            restart := True
         until
            not restart
         loop
            restart := False
            check_server
            run
         end

         cleanup
      rescue
         cleanup
         crash
      end

   cleanup is
      do
         if fifo.exists(client_fifo) then
            delete(client_fifo)
         end
         delete(client_fifo.substring(client_fifo.lower, client_fifo.upper - 5)) -- "/fifo".count
      end

   run is
      require
         not fifo.exists(client_fifo)
      deferred
      end

feature {}
   fifo: FIFO

   server_fifo: FIXED_STRING
   vault: FIXED_STRING
   logdir: FIXED_STRING

   check_server is
      do
         if not file_exists(vault) then
            read_new_master(once "This is a new vault")
            create_vault
            start_server
            send_master
         elseif not fifo.exists(server_fifo) then
            start_server
            master_pass.copy(read_master(once "Please enter your encryption phrase%Nto open the password vault."))
            send_master
         end
      end

   start_server is
      require
         not fifo.exists(server_fifo)
      local
         proc: PROCESS
      do
         proc := processor.execute_to_dev_null(once "nohup", once "daemon '#(1)' '#(2)' '#(3)/daemon.log' '#(4)'" # server_fifo # vault # logdir # conf_filename)
         if proc.is_connected then
            proc.wait
            fifo.wait_for(server_fifo)
            fifo.sleep(250)
         end
      ensure
         fifo.exists(server_fifo)
      end

feature {} -- master phrase
   master_pass: STRING is ""

   read_master (text: ABSTRACT_STRING): STRING is
      local
         proc: PROCESS
      do
         proc := processor.execute_redirect(once "zenity", zenity_args(text))
         if proc.is_connected then
            proc.output.read_line
            Result := proc.output.last_string
            proc.wait
         end
      end

   zenity_args (text: ABSTRACT_STRING): ABSTRACT_STRING is
      do
         Result := once "--entry --hide-text --title=Password --text=%"#(1)%"" # text
      end

   send_master is
      require
         fifo.exists(server_fifo)
      do
         send(once "master #(1)" # master_pass)
      end

   send_save is
      do
         send(once "save #(1)" # vault)
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
            tfw.put_line(string)
            tfw.flush

            -- give time to the OS and the daemon to get the message before closing the connection
            fifo.sleep(50)

            tfw.disconnect
         end
      end

feature {} -- xclip
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
         proc := processor.execute(once "xclip", once "-selection #(1) -loops 3" # selection)
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

feature {} -- create a brand new vault
   read_new_master (reason: ABSTRACT_STRING) is
      local
         pass1, pass2: STRING; text: ABSTRACT_STRING
      do
         from
            text := once "#(1),%Nplease enter an encryption phrase." # reason
         until
            pass1 /= Void
         loop
            pass1 := once ""
            pass1.copy(read_master(text))
            text := once "Please enter the same encryption phrase again." # reason
            pass2 := read_master(text)
            if not pass1.is_equal(pass2) then
               text := once "Your phrases did not match.%N#(1),%Nplease enter an encryption phrase." # reason
               pass1 := Void
            end
         end
         check
            by_construction: pass1.is_equal(pass2)
         end
         master_pass.copy(pass1)
      end

   create_vault is
      local
         new_vault: VAULT
      do
         create new_vault.make(vault)
         new_vault.open_new(master_pass)
         new_vault.save(vault.out)
         new_vault.close
      end

invariant
   server_fifo /= Void
   client_fifo /= Void
   vault /= Void

end
