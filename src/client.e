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
   client_fifo: FIXED_STRING
   restart: BOOLEAN

   main is
      do
         default_create
         direct_error := True

         if argument_count < 3 or else not check_argument_count then
            std_error.put_line("Usage: #(1) <server fifo> <vault> <log dir>#(2)" # command_name # extra_args)
            die_with_code(1)
         end

         client_fifo := fifo.tmp
         if client_fifo = Void then
            std_error.put_line("#(1): could not create client fifo!" # command_name)
            die_with_code(1)
         end

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

   check_argument_count: BOOLEAN is
      deferred
      end

   extra_args: STRING is
      deferred
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
            read_master(once "Please enter your encryption phrase to open the password vault.")
            send_master
         end
      end

   start_server is
      require
         not fifo.exists(server_fifo)
      local
         proc: PROCESS
      do
         proc := execute_command_line((once "daemon #(1) #(2) #(3)/daemon.log" # server_fifo # vault # logdir).out)
         if proc.is_connected then
            proc.wait
            fifo.wait_for(server_fifo)
         end
      ensure
         fifo.exists(server_fifo)
      end

feature {} -- master phrase
   master_pass: STRING

   read_master (text: ABSTRACT_STRING) is
      local
         proc: PROCESS
      do
         proc := execute(once "zenity", zenity_args(text.out))
         if proc.is_connected then
            proc.output.read_line
            master_pass := proc.output.last_string
            proc.wait
         end
      end

   zenity_args (text: ABSTRACT_STRING): FAST_ARRAY[STRING] is
      do
         Result := {FAST_ARRAY[STRING] <<
                                         "--entry",
                                         "--hide-text",
                                         "--title=Password",
                                         ("--text=#(1)" # text).out
                                       >> }
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
            fifo.sleep(50) -- give time to the OS and the daemon to get the message before closing the connection
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

feature {} -- create a brand new vault
   read_new_master (reason: ABSTRACT_STRING) is
      local
         pass1: STRING; text: ABSTRACT_STRING
      do
         from
            text := once "#(1), please enter an encryption phrase." # reason
         until
            pass1 /= Void
         loop
            read_master(text)
            pass1 := master_pass.twin
            text := once "#(1), please enter the same encryption phrase again." # reason
            read_master(text)
            if not pass1.is_equal(master_pass) then
               text := once "Your phrases did not match.%N#(1), please enter an encryption phrase." # reason
               pass1 := Void
            end
         end
         check
            by_construction: pass1.is_equal(master_pass)
         end
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
