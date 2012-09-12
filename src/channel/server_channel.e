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
deferred class SERVER_CHANNEL

insert
   JOB
      export {SERVER}
         prepare, is_ready, continue, done, restart
      end

feature {SERVER}
   on_receive (command: PROCEDURE[TUPLE[RING_ARRAY[STRING]]]) is
      require
         command /= Void
      do
         if commands = Void then
            create commands.make(0)
         end
         commands.add_last(command)
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
   commands: FAST_ARRAY[PROCEDURE[TUPLE[RING_ARRAY[STRING]]]]
   jobs: FAST_ARRAY[PROCEDURE[TUPLE[JOB]]]

   fire_receive (command: RING_ARRAY[STRING]) is
      do
         if commands /= Void then
            commands.do_all(agent (cmd: PROCEDURE[TUPLE[RING_ARRAY[STRING]]]; c: RING_ARRAY[STRING]) is do cmd.call([c]) end (?, command))
         end
      end

   fire_new_job (job: JOB) is
      do
         if jobs /= Void then
            jobs.do_all(agent (jb: PROCEDURE[TUPLE[JOB]]; j: JOB) is do jb.call([j]) end (?, job))
         end
      end

end
