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
class CLIENT_SOCKET

inherit
   CLIENT_CHANNEL

insert
   CONFIGURABLE
   LOGGING

create {ANY}
   make

feature {CLIENT}
   server_running (when_reply: PROCEDURE[TUPLE[BOOLEAN]])
      do
         when_reply.call([is_server_running])
      end

   server_start
      local
         proc: PROCESS; arg: ABSTRACT_STRING; processor: PROCESSOR; extern: EXTERN
      do
         log.trace.put_line(once "starting server...")
         if configuration.argument_count = 1 then
            arg := configuration.argument(1)
         end

         proc := processor.execute_to_dev_null(once "server", arg)
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

   call (query: MESSAGE; when_reply: PROCEDURE[TUPLE[MESSAGE]])
      local
         reply: MESSAGE
      do
         busy := True
         streamer.write_message(query, channel)
         --channel.put_new_line
         channel.flush
         log.trace.put_line("Reading message...")
         streamer.read_message(channel)
         busy := False
         if streamer.error /= Void then
            log.error.put_line(streamer.error)
         else
            reply := streamer.last_message
            when_reply.call([reply])
            --| **** TODO reply.clean
         end
         --| **** TODO query.clean
      end

   is_ready: BOOLEAN
      do
         Result := not busy
      end

   cleanup
      do
         if channel /= Void then
            channel.disconnect
         end
      end

feature {}
   make (tmpdir: ABSTRACT_STRING)
      require
         tmpdir /= Void
      do
         create access.make(create {IPV4_ADDRESS}.make(127, 0, 0, 1), socket.port, True)
         channel := access.stream
         log.info.put_line(once "Starting client on port #(1)" # socket.port.out)
      end

   is_server_running: BOOLEAN
      do
         if channel = Void or else not channel.is_connected then
            channel := access.stream
         end
         Result := channel /= Void and then channel.is_connected
         log.info.put_line(once "Server is running: #(1)" # Result.out)
      end

   access: TCP_ACCESS

   channel: SOCKET_INPUT_OUTPUT_STREAM

   socket: SOCKET_CONF

   busy: BOOLEAN

   streamer: MESSAGE_STREAMER
      once
         create Result.make
      end

   configuration_section: STRING "client_socket"

invariant
   access /= Void

end -- class CLIENT_SOCKET
