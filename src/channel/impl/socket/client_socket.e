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
class CLIENT_SOCKET

inherit
   CLIENT_CHANNEL

insert
   CONFIGURABLE
   LOGGING

create {CHANNEL_FACTORY}
   make

feature {CLIENT}
   server_running: BOOLEAN is
      do
         if channel = Void or else not channel.is_connected then
            channel := access.stream
         end
         Result := channel /= Void and then channel.is_connected
         log.info.put_line(once "Server is running: #(1)" # Result.out)
      end

   server_start is
      local
         proc: PROCESS; arg: ABSTRACT_STRING
         processor: PROCESSOR
         extern: EXTERN
      do
         log.trace.put_line(once "starting server...")
         if configuration.argument_count = 1 then
            arg := once "server %"#(1)%"" # configuration.argument(1)
         else
            arg := once "server"
         end
         proc := processor.execute_to_dev_null(once "nohup", arg)
         if proc.is_connected then
            proc.wait
            extern.sleep(200)
            if proc.status = 0 then
               log.trace.put_line(once "server is starting")
            else
               log.error.put_line(once "server not started! (exit=#(1))" # proc.status.out)
               sedb_breakpoint
               die_with_code(proc.status)
            end
         end
      end

   call (query: MESSAGE; when_reply: PROCEDURE[TUPLE[MESSAGE]]) is
      do
         busy := True
         streamer.write_message(query, channel)
         channel.put_new_line
         channel.flush
         streamer.read_message(channel)
         busy := False
         if streamer.error /= Void then
            log.error.put_line(streamer.error)
         else
            when_reply.call([streamer.last_message])
         end
      end

   is_ready: BOOLEAN is
      do
         Result := not busy
      end

   server_is_ready: BOOLEAN is
      do
         Result := server_running and then not busy
      end

   cleanup is
      do
         if channel /= Void then
            channel.disconnect
         end
      end

feature {}
   make (tmpdir: ABSTRACT_STRING) is
      require
         tmpdir /= Void
      local
      do
         create access.make(create {IPV4_ADDRESS}.make(127,0,0,1), socket.port, True)
         channel := access.stream
         log.info.put_line(once "Starting client on port #(1)" # socket.port.out)
      end

   access: TCP_ACCESS
   channel: SOCKET_INPUT_OUTPUT_STREAM
   socket: SOCKET

   busy: BOOLEAN

   streamer: MESSAGE_STREAMER is
      once
         create Result.make
      end

invariant
   access /= Void

end
