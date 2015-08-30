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
class CLIENT_FIFO

inherit
   CLIENT_CHANNEL

insert
   SHARED_FIFO
   CONFIGURABLE
   LOGGING
   FILE_TOOLS

create {CHANNEL_FACTORY}
   make

feature {CLIENT}
   server_running (when_reply: PROCEDURE[TUPLE[BOOLEAN]])
      local
         tfr: TEXT_FILE_READ; pid: INTEGER; shared: SHARED
         res: BOOLEAN
      do
         if extern.exists(server_fifo) then
            check
               extern.exists(server_fifo)
            end
            if file_exists(shared.server_pidfile) then
               create tfr.connect_to(shared.server_pidfile)
               if tfr.is_connected then
                  tfr.read_line
                  if tfr.last_string.is_integer then
                     pid := tfr.last_string.to_integer
                     if extern.process_running(pid) then
                        res := True
                     end
                  end

                  tfr.disconnect
               end

               if not res then
                  delete(shared.server_pidfile)
               end
            end

            if not res then
               delete(server_fifo)
            end
         end

         when_reply.call([res])
      end

   server_start
      local
         proc: PROCESS; arg: ABSTRACT_STRING; processor: PROCESSOR
      do
         log.trace.put_line(once "starting server...")
         if configuration.argument_count = 1 then
            arg := configuration.argument(1)
         end

         proc := processor.execute_to_dev_null(once "server", arg)
         if proc.is_connected then
            proc.wait
            if proc.status = 0 then
               log.trace.put_line(once "server started.")
            else
               log.error.put_line(once "server not started! (exit=#(1))" # proc.status.out)
               sedb_breakpoint
               die_with_code(proc.status)
            end

            extern.wait_for(server_fifo)
            extern.sleep(100)
         end
      ensure
         extern.exists(server_fifo)
      end

   call (query: MESSAGE; when_reply: PROCEDURE[TUPLE[MESSAGE]])
      local
         tfw: TEXT_FILE_WRITE; tfr: TEXT_FILE_READ
      do
         log.trace.put_line(once "Calling: #(1)" # query.generating_type)
         extern.make(client_fifo)
         extern.sleep(25)
         create tfw.connect_to(server_fifo)
         if tfw.is_connected then
            log.trace.put_line(once "Writing to server...")
            tfw.put_line(client_fifo)
            streamer.write_message(query, tfw)
            tfw.put_new_line
            tfw.flush
            log.trace.put_line(once "... server fifo written to.")

            extern.wait_for(client_fifo)
            create tfr.connect_to(client_fifo)
            if tfr.is_connected then
               log.trace.put_line(once "Reading from server...")
               streamer.read_message(tfr)
               tfr.disconnect
               delete(client_fifo)
               log.trace.put_line(once "... client fifo read from.")

               if streamer.error /= Void then
                  log.error.put_line(streamer.error)
               else
                  log.trace.put_line(once "Calling reply callback...")
                  when_reply.call([streamer.last_message])
                  log.trace.put_line(once "... reply callback returned.")
               end
            else
               log.error.put_line(once "**** Could not connect to client fifo!!")
            end

            tfw.disconnect
         else
            log.error.put_line(once "**** Could not connect to server fifo!!")
         end
      end

   is_ready: BOOLEAN
      do
         Result := not extern.exists(client_fifo)
      end

   cleanup
      do
         if extern.exists(client_fifo) then
            delete(client_fifo)
         end
         delete(client_fifo.substring(client_fifo.lower, client_fifo.upper - 5)) -- "/fifo".count
      end

feature {}
   client_fifo: FIXED_STRING

   make (tmpdir: ABSTRACT_STRING)
      require
         tmpdir /= Void
      do
         client_fifo := ("#(1)/fifo" # tmpdir).intern
      end

   streamer: MESSAGE_STREAMER
      once
         create Result.make
      end

invariant
   client_fifo /= Void

end -- class CLIENT_FIFO
