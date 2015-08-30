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
deferred class SERVER_CHANNEL

insert
   JOB
      export {SERVER} prepare, is_ready, continue, done, restart
      end
   LOGGING

feature {SERVER}
   on_receive (message: FUNCTION[TUPLE[MESSAGE], MESSAGE])
      require
         message /= Void
      do
         if messages = Void then
            create messages.make(0)
         end
         messages.add_last(message)
      end

   on_new_job (job: PROCEDURE[TUPLE[JOB]])
      require
         job /= Void
      do
         if jobs = Void then
            create jobs.make(0)
         end
         jobs.add_last(job)
      end

   disconnect
      deferred
      end

   cleanup
      deferred
      end

feature {}
   messages: FAST_ARRAY[FUNCTION[TUPLE[MESSAGE], MESSAGE]]

   jobs: FAST_ARRAY[PROCEDURE[TUPLE[JOB]]]

   fire_receive (query: MESSAGE): MESSAGE
      require
         query /= Void
      local
         reply: REFERENCE[MESSAGE]; replied: BOOLEAN
      do
         if messages /= Void then
            create reply
            replied := messages.exists(agent reply_to(?, query, reply))
            if replied then
               Result := reply.item
            end
         end
      end

   reply_to (action: FUNCTION[TUPLE[MESSAGE], MESSAGE]; query: MESSAGE; reply_ref: REFERENCE[MESSAGE]): BOOLEAN
      require
         reply_ref.item = Void
      local
         reply: MESSAGE
      do
         reply := action.item([query])
         if reply /= Void then
            reply_ref.set_item(reply)
            Result := True -- stop iterating
         end
      ensure
         Result implies reply_ref.item /= Void
      end

   fire_new_job (job: JOB)
      require
         job /= Void
      do
         if jobs /= Void then
            jobs.for_each(agent (jb: PROCEDURE[TUPLE[JOB]])
               do
                  jb.call([job])
               end(?))
         end
      end

end -- class SERVER_CHANNEL
