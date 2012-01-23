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
   make

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
         when "stop" then
            send("stop")
            fifo.sleep(100)
            die_with_code(0)
         else
            command.add_first(cmd) -- yes, add it again... it's a ring array so no harm done
            run_get
         end
      ensure
         not fifo.exists(client_fifo)
      end

   get_data (cmd: ABSTRACT_STRING; action: PROCEDURE[TUPLE[INPUT_STREAM]]) is
         -- communication with the daemon
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

feature {} -- local vault commands
   run_get is
      do
         do_get(command.first, agent xclip)
      end

   get_back (stream: INPUT_STREAM; key: ABSTRACT_STRING; callback: PROCEDURE[TUPLE[STRING]]) is
      require
         callback /= Void
      do
         stream.read_line
         if not stream.end_of_input then
            data.clear_count
            stream.last_string.split_in(data)
            if data.count = 2 then
               callback.call([data.last])
            else
               check data.count = 1 end
               io.put_line(once "[1mUnknown password:[0m #(1)" # key)
            end
         end
      end

   do_get (key: ABSTRACT_STRING; callback: PROCEDURE[TUPLE[STRING]]) is
         -- get key
      require
         callback /= Void
      do
         get_data(once "get #(1) #(2)" # client_fifo # key,
                  agent get_back(?, key, callback))
      end

   run_add is
         -- add key
      local
         cmd: ABSTRACT_STRING; pass: STRING
      do
         if command.count > 1 then
            inspect
               command.last
            when "generated" then
               cmd := once "set #(1) #(2)" # client_fifo # command.first
            when "prompt" then
               pass := read_password(once "Please enter the new password for #(1)" # command.first, on_cancel)
               if pass /= Void then
                  cmd := once "set #(1) #(2) #(3)" # client_fifo # command.first # pass
               end
            else
               io.put_line(once "[1mError:[0m unrecognized last argument '#(1)'" # command.last)
            end
         elseif not command.is_empty then
            cmd := once "set #(1) #(2)" # client_fifo # command.first
         end
         if cmd /= Void then
            get_data(cmd,
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
                                 xclip(once "")
                                 io.put_line(once "[1mError[0m") -- ???
                              end
                           end
                        end)
            send_save
         end
      end

   run_rem is
         -- remove key
      do
         get_data(once "unset #(1) #(2)" # client_fifo # command.first,
                  agent (stream: INPUT_STREAM) is
                     do
                        stream.read_line
                        if not stream.end_of_input then
                           xclip(once "")
                           io.put_line(once "[1mDone[0m")
                        end
                     end)
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
                        fifo.splice(stream, str)
                        less(str.to_string)
                     end)
      end

feature {} -- help
   run_help is
      do
         less(once "[
                    [1;32mKnown commands[0m

                    [33madd <key> [how][0m    Add a new password. Needs at least a key.
                                       If [33m[how][0m is either not specified or "generated" then
                                       the password is randomly generated.
                                       If [33m[how][0m is "prompt" then the password is asked.
                                       If the password already exists it is changed.
                                       In all cases the password is stored in the clipboard.

                    [33mrem <key>[0m          Removes the password corresponding to the given key.

                    [33mlist[0m               List the known passwords (show only the keys).

                    [33msave[0m               Save the password vault upto the server.

                    [33mload[0m               Replace the local vault with the server's version.
                                       Note: in that case you will be asked for the new vault
                                       password (the previous vault is closed).

                    [33mmerge[0m              Load the server version and compare to the local one.
                                       Keep the most recent keys and save the merged version
                                       back to the server.

                    [33mmaster[0m             Change the master password.
                                       [1m(not yet implemented)[0m

                    [33mstop[0m               Stop the daemon and closes the administration console.

                    [33mhelp[0m               Show this screen :-)

                    Any other input is understood as a password request using the given key.
                    If that key exists the password is stored in the clipboard.

                    ]")
      end

feature {} -- remote vault management
   config_key_login: FIXED_STRING is
      once
         Result := "remote.login".intern
      end

   config_key_password: FIXED_STRING is
      once
         Result := "remote.password".intern
      end

   config_key_vault_url: FIXED_STRING is
      once
         Result := "remote.vault_url".intern
      end

   is_anonymous: BOOLEAN is
      do
         Result := not has_conf(config_key_login) or else not has_conf(config_key_password)
      end

   curl_arguments (option, file: ABSTRACT_STRING): ABSTRACT_STRING is
      require
         option.is_equal(once "-T") or else option.is_equal(once "-o")
         file /= Void
      local
         pass: REFERENCE[STRING]
         url: FIXED_STRING
      do
         url := conf(config_key_vault_url)
         if url = Void then
            std_output.put_line(once "[1mMissing vault url![0m")
         else
            Result := once "-\# #(1) '#(2)' '#(3)'" # option # file # url
            if not is_anonymous then
               create pass
               do_get(conf(config_key_password),
                      agent (p: STRING; p_ref: REFERENCE[STRING]) is
                         do
                            p_ref.set_item(p)
                         end (?, pass))
               if pass.item /= Void then
                  Result := once "#(1) -u #(2):#(3)" # Result # conf(config_key_login) # pass.item
               end
            end
         end
      end

   run_save is
         -- save to remote
      local
         proc: PROCESS; arg: like curl_arguments
      do
         arg := curl_arguments(once "-T", shared.vault_file)
         if arg /= Void then
            std_output.put_line(once "[32mPlease wait...[0m")
            proc := processor.execute(once "curl", arg)
            if proc.is_connected then
               proc.wait
            end
         end
      end

   run_load is
         -- load from remote
      local
         proc: PROCESS
      do
         -- shut the daemon down
         send("stop")

         std_output.put_line(once "[32mPlease wait...[0m")
         proc := processor.execute(once "curl", curl_arguments(once "-o", shared.vault_file))
         if proc.is_connected then
            proc.wait
         end

         -- stop the inner command loop
         stop := True
         -- ask the main client loop to start again (will restart the daemon)
         restart := True
      end

   on_cancel: PROCEDURE[TUPLE] is
      once
         Result := agent is do std_output.put_line(once "[1mCancelled.[0m") end
      end

   run_merge is
         -- merge from remote
      local
         merge_pass0, merge_pass: STRING
         proc: PROCESS
      do
         std_output.put_line(once "[32mPlease wait...[0m")
         proc := processor.execute(once "curl", curl_arguments(once "-o", merge_vault))
         if proc.is_connected then
            proc.wait
         end

         merge_pass0 := read_password(once "Please enter the encryption phrase%Nto the remote vault%N(just leave empty if the same as the current vault's)", on_cancel)
         if merge_pass0 = Void then
            -- cancelled
         else
            if merge_pass0.is_empty then
               merge_pass := master_pass
            else
               merge_pass := once ""
               merge_pass.copy(merge_pass0)
            end
            get_data("merge #(1) #(2) #(3)" # client_fifo # merge_vault # merge_pass,
                     agent (stream: INPUT_STREAM) is
                        do
                           stream.read_line
                           if not stream.end_of_input then
                              xclip(once "")
                              io.put_line(once "[1mDone[0m")
                           end
                        end)
            delete(merge_vault)
            send_save
         end
      end

feature {} -- helpers
   merge_vault: FIXED_STRING is
      once
         Result := ("#(1)/merge_vault" # tmpdir).intern
      end

   less (string: ABSTRACT_STRING) is
      local
         proc: PROCESS
      do
         proc := processor.execute(once "less", once "-R")
         if proc.is_connected then
            proc.input.put_string(string)
            proc.input.flush
            proc.input.disconnect
            proc.wait
         end
      end

end
