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
class CLIENT_ZMQ

inherit
   CLIENT_CHANNEL

insert
   CONFIGURABLE
   LOGGING

create {ANY}
   make

feature {CLIENT}
   server_running (when_reply: PROCEDURE[TUPLE[BOOLEAN]])
      local
         timeout: TIME
      do
         timeout.update
         timeout.add_second(2)
         do_call(
            create {QUERY_PING}.make(once "server_running"),
            agent on_server_running(?, when_reply),
            agent on_server_not_running(when_reply),
            agent is_timeout(timeout)
         )
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
      do
         do_call(query, when_reply, agent do_nothing, agent: BOOLEAN then False end)
      end

   is_ready: BOOLEAN
      do
         Result := not data.busy
      end

   cleanup
      do
         hub.stop
      end

feature {}
   do_nothing
      do
      end

   do_call (query: MESSAGE; when_reply: PROCEDURE[TUPLE[MESSAGE]]; when_timeout: PROCEDURE[TUPLE]; timeout: PREDICATE[TUPLE])
      require
         when_reply /= Void
         when_timeout /= Void
      local
         sos: STRING_OUTPUT_STREAM; s: STRING
         f: EZMQ_FLAGS
      do
         data.set(agent on_call_reply(?, when_reply), when_timeout, timeout)
         s := ""
         create sos.connect_to(s)
         streamer.write_message(query, sos)
         socket.send(s, f.None)
      end

   on_call_reply (reply: ABSTRACT_STRING; when_reply: PROCEDURE[TUPLE[MESSAGE]])
      local
         sis: STRING_INPUT_STREAM
      do
         create sis.from_string(reply)
         if streamer.error /= Void then
            log.error.put_line(streamer.error)
         else
            when_reply.call([streamer.last_message])
         end
      end

   on_input (a_hub: EZMQ_HUB; a_socket: EZMQ_SOCKET; input: ABSTRACT_STRING; a_data: EZMQ_DATA): BOOLEAN
      require
         a_hub = hub
         a_socket = socket
         a_data = data
      do
         if data.busy then
            data.when_reply.call([input])
            data.clear
            Result := True
         else
            log.warning.put_line(once "Spurious input from server (ignored)")
         end
      end

   calc_timeout (a_hub: EZMQ_HUB; a_data: EZMQ_DATA): TIME
      require
         a_hub = hub
         a_data = data
      do
         Result.update
         Result.add_second(1)
      end

   is_timeout (timeout: TIME): BOOLEAN
      local
         now: TIME
      do
         now.update
         Result := now > timeout
      end

   on_timeout (a_hub: EZMQ_HUB; a_data: EZMQ_DATA): BOOLEAN
      require
         a_hub = hub
         a_data = data
      do
         if data.busy and then data.timeout.item([]) then
            data.on_timeout.call([])
            data.clear
            Result := True
         end
      end

   on_server_running (a_reply: MESSAGE; when_reply: PROCEDURE[TUPLE[BOOLEAN]])
      local
         reply: REPLY_PING
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.id.is_equal(once "server_running") then
               when_reply.call([True])
            else
               log.error.put_line(once "Invalid reply id")
            end
         else
            log.error.put_line(once "Unexpected reply")
         end
      end

   on_server_not_running (when_reply: PROCEDURE[TUPLE[BOOLEAN]])
      do
         when_reply.call([False])
      end

feature {}
   make (tmpdir: ABSTRACT_STRING)
      require
         tmpdir /= Void
      local
         t: EZMQ_TYPE
         endpoint: EZMQ_ENDPOINT
      do
         create {EZMQ_ENDPOINT_ZMQ} endpoint.tcp(zmq.address, zmq.port)
         create {EZMQ_SOCKET_ZMQ_CONNECT} socket.make(t.Req, endpoint)
         hub := {EZMQ_HUB_ZMQ <<
            create {EZMQ_POLL_INPUT}.make(socket, agent on_input(?, ?, ?, ?)),
            create {EZMQ_POLL_TIMEOUT}.make(agent calc_timeout(?, ?), agent on_timeout(?, ?))
         >>}

         create data
         hub.run(data)
      end

   hub: EZMQ_HUB
   socket: EZMQ_SOCKET

   zmq: ZMQ

   data: CLIENT_ZMQ_DATA

   streamer: MESSAGE_STREAMER
      once
         create Result.make
      end

   configuration_section: STRING "client_zmq"

end -- class CLIENT_ZMQ
