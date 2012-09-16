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
deferred class CLIENT

insert
   GLOBALS
   FILE_TOOLS

feature {}
   processor: PROCESSOR

   tmpdir: FIXED_STRING
   channel: CLIENT_CHANNEL
   restart: BOOLEAN

   preload is
      do
         inspect
            configuration.argument_count
         when 0 then
            -- OK
         when 1 then
            configuration.parse_extra_conf(configuration.argument(1))
         else
            std_error.put_line("Usage: #(1) [<fallback conf>]")
            die_with_code(1)
         end

         if configuration.main_config = Void then
            std_error.put_line(once "Could not find any valid configuration file")
            die_with_code(1)
         end
      end

   main is
      local
         channel_factory: CHANNEL_FACTORY
         extern: EXTERN
      do
         tmpdir := extern.tmp
         if tmpdir = Void then
            log.error.put_line("#(1): could not create tmp directory!" # command_name)
            die_with_code(1)
         end

         channel := channel_factory.new_client_channel(tmpdir)

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
         if channel /= Void then
            channel.cleanup
         end
      end

   run is
      require
         channel.is_ready
      deferred
      end

feature {}
   exceptions: EXCEPTIONS

   server_pidfile: FIXED_STRING is
      do
         Result := shared.server_pidfile
      end

   check_server is
      do
         if not file_exists(shared.vault_file) then
            check
               not channel.server_running
               not file_exists(server_pidfile)
            end
            server_bootstrap
         elseif not channel.server_running then
            server_restart
         else
            server_open
         end
      end

   server_bootstrap is
      do
         log.info.put_line(once "Creating new vault: #(1)" # shared.vault_file)
         read_new_master(once "This is a new vault")
         channel.server_start
         send_master(True)
      end

   server_restart is
      do
         log.info.put_line(once "Starting server using vault: #(1)" # shared.vault_file)
         channel.server_start
         if channel.server_running then
            master_pass.copy(read_password(once "Please enter your encryption phrase%Nto open the password vault.", Void))
            send_master(True)
         else
            log.error.put_line(once "Could not start server!")
            die_with_code(1)
         end
      end

   server_open is
      do
         call_server(create {QUERY_IS_OPEN}.make, agent when_open)
      end

   when_open (a_reply: MESSAGE) is
      local
         reply: REPLY_IS_OPEN
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.is_open then
               log.info.put_line(once "Server vault is already open")
            else
               master_pass.copy(read_password(once "Please enter your encryption phrase%Nto open the password vault.", Void))
               send_master(False)
            end
         else
            log.error.put_line(once "Unexpected reply")
         end
      end

   call_server (query: MESSAGE; when_reply: PROCEDURE[TUPLE[MESSAGE]]) is
         -- communication with the server
      do
         channel.call(query, when_reply)
      end

feature {} -- get a password from the server
   data: RING_ARRAY[STRING] is
      once
         create Result.with_capacity(16, 0)
      end

   get_back (a_reply: MESSAGE; key: ABSTRACT_STRING; callback: PROCEDURE[TUPLE[STRING]]; when_unknown: PROCEDURE[TUPLE[ABSTRACT_STRING]]) is
      require
         callback /= Void
         when_unknown /= Void
      local
         reply: REPLY_GET
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
               callback.call([reply.pass])
            else
               log.error.put_line(reply.error)
               when_unknown.call([key])
            end
         else
            log.error.put_line(once "Unexpected reply")
         end
      end

   do_get (key: ABSTRACT_STRING; callback: PROCEDURE[TUPLE[STRING]]; when_unknown: PROCEDURE[TUPLE[ABSTRACT_STRING]]) is
         -- get key
      require
         callback /= Void
         when_unknown /= Void
      do
         call_server(create {QUERY_GET}.make(key.out), agent get_back(?, key, callback, when_unknown))
      end

   unknown_key (key: ABSTRACT_STRING) is
      deferred
      end

   do_ping is
      do
         call_server(create {QUERY_PING}.make(once ""), agent when_ping)
      end

   when_ping (a_reply: MESSAGE) is
      local
         reply: REPLY_PING
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if not reply.error.is_empty then
               log.error.put_line(reply.error)
            end
         else
            log.error.put_line(once "Unexpected reply")
         end
      end

feature {REMOTE}
   get_password (key: ABSTRACT_STRING): STRING is
      local
         pass: REFERENCE[STRING]
      do
         create pass
         do_get(key,
                agent (p: STRING; p_ref: REFERENCE[STRING]) is
                   do
                      p_ref.set_item(p)
                   end (?, pass),
                agent unknown_key)
         Result := pass.item
      end

feature {} -- master phrase
   master_pass: STRING is ""

   read_password (text: ABSTRACT_STRING; on_cancel: PROCEDURE[TUPLE]): STRING is
      require
         text /= Void
      local
         proc: PROCESS
      do
         proc := processor.execute_redirect(once "zenity", zenity_args(text))
         if proc.is_connected then
            proc.output.read_line
            if not proc.output.end_of_input then
               Result := proc.output.last_string
            end
            proc.wait
            if proc.status /= 0 then
               if on_cancel /= Void then
                  on_cancel.call([])
                  Result := Void
               else
                  std_error.put_line(once "Cancelled.")
                  die_with_code(1)
               end
            end
         end
      end

   zenity_args (text: ABSTRACT_STRING): ABSTRACT_STRING is
      do
         Result := once "--entry --hide-text --title=Password --text=%"#(1)%"" # text
      end

   send_master (settle: BOOLEAN) is
      require
         channel.server_running
      do
         if settle then
            log.info.put_line(once "Pinging server to settle queues") -- TODO move that, fifo trick only
            do_ping
            do_ping
            do_ping
         end
         log.info.put_line(once "Sending master password")
         call_server(create {QUERY_MASTER}.make(master_pass), agent when_master)
      end

   when_master (a_reply: MESSAGE) is
      local
         reply: REPLY_MASTER
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if not reply.error.is_empty then
               log.error.put_line(reply.error)
            end
         else
            log.error.put_line(once "Unexpected reply")
         end
      end

   send_save is
      do
         call_server(create {QUERY_SAVE}.make, agent when_save)
      end

   when_save (a_reply: MESSAGE) is
      local
         reply: REPLY_SAVE
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if not reply.error.is_empty then
               log.error.put_line(reply.error)
            end
         else
            log.error.put_line(once "Unexpected reply")
         end
      end

feature {} -- xclip
   xclip (string: ABSTRACT_STRING) is
      require
         string /= Void
      local
         procs: FAST_ARRAY[PROCESS]
      do
         create procs.with_capacity(xclipboards.count)
         xclipboards.do_all(agent xclip_select(string, ?, procs))
         procs.do_all(agent {PROCESS}.wait)
      end

   xclip_select (string: ABSTRACT_STRING; selection: STRING; procs: FAST_ARRAY[PROCESS]) is
      require
         procs /= Void
      local
         proc: PROCESS
      do
         proc := processor.execute(once "xclip", once "-selection #(1)" # selection)
         if proc.is_connected then
            proc.input.put_line(string)
            proc.input.disconnect
            procs.add_last(proc)
         end
      ensure
         procs.count = old procs.count + 1
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
            pass1.copy(read_password(text, Void))
            text := once "Please enter the same encryption phrase again." # reason
            pass2 := read_password(text, Void)
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

end
