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
         Result := channel.is_connected
         log.info.put_line(once "Server is running: #(1)" # Result.out)
      end

   server_start is
      local
         proc: PROCESS; arg: ABSTRACT_STRING
         processor: PROCESSOR
      do
         log.info.put_line(once "starting server...")
         if configuration.argument_count = 1 then
            arg := once "server %"#(1)%"" # configuration.argument(1)
         else
            arg := once "server"
         end
         proc := processor.execute_to_dev_null(once "nohup", arg)
         if proc.is_connected then
            proc.wait
            if proc.status = 0 then
               log.info.put_line(once "server started.")
            else
               log.error.put_line(once "server not started! (exit=#(1))" # proc.status.out)
               sedb_breakpoint
               die_with_code(proc.status)
            end
         end
      end

   send (string: ABSTRACT_STRING) is
      do
         channel.put_line(string)
      end

   call (verb, arguments: ABSTRACT_STRING; action: PROCEDURE[TUPLE[INPUT_STREAM]]) is
      do
         busy := True
         if arguments = Void then
            channel.put_line(once "#(1) #(2)" # verb # socket.port.out)
         else
            channel.put_line(once "#(1) #(2) #(3)" # verb # socket.port.out # arguments)
         end
         channel.flush
         action.call([channel])
         busy := False
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
         channel.disconnect
      end

feature {}
   make (tmpdir: ABSTRACT_STRING) is
      require
         tmpdir /= Void
      local
         access: TCP_ACCESS
      do
         create access.make(create {IPV4_ADDRESS}.make(127,0,0,1), socket.port)
         channel := access.stream
         log.info.put_line(once "Starting client on port #(1)" # socket.port.out)
      end

   channel: SOCKET_INPUT_OUTPUT_STREAM
   socket: SOCKET

   busy: BOOLEAN

invariant
   channel /= Void

end
