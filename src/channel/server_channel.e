-- This file is part of pwdmgr.
-- Copyright (C) 2012-2014 Cyril Adrian <cyril.adrian@gmail.com>
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
deferred class SERVER_CHANNEL

insert
   JOB
      export {SERVER}
         prepare, is_ready, continue, done, restart
      end
   LOGGING

feature {SERVER}
   on_receive (message: FUNCTION[TUPLE[MESSAGE], MESSAGE]) is
      require
         message /= Void
      do
         if messages = Void then
            create messages.make(0)
         end
         messages.add_last(message)
      end

   on_new_job (job: PROCEDURE[TUPLE[JOB]]) is
      require
         job /= Void
      do
         if jobs = Void then
            create jobs.make(0)
         end
         jobs.add_last(job)
      end

   disconnect is
      deferred
      end

   cleanup is
      deferred
      end

feature {}
   messages: FAST_ARRAY[FUNCTION[TUPLE[MESSAGE], MESSAGE]]
   jobs: FAST_ARRAY[PROCEDURE[TUPLE[JOB]]]

   fire_receive (query: MESSAGE): MESSAGE is
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

   reply_to (action: FUNCTION[TUPLE[MESSAGE], MESSAGE]; query: MESSAGE; reply_ref: REFERENCE[MESSAGE]): BOOLEAN is
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

   fire_new_job (job: JOB) is
      require
         job /= Void
      do
         if jobs /= Void then
            jobs.do_all(agent (jb: PROCEDURE[TUPLE[JOB]]; j: JOB) is do jb.call([j]) end (?, job))
         end
      end

end
