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
expanded class PROCESSOR
   --
   -- A façade to the actual processor implementation
   --

insert
   TEST_FACADE[PROCESSOR_DEF]

feature {ANY}
   execute (command, arguments: ABSTRACT_STRING): PROCESS
      require
         command /= Void
      do
         Result := def.execute(command, arguments)
      ensure
         Result /= Void
      end

   execute_redirect (command, arguments: ABSTRACT_STRING): PROCESS
      require
         command /= Void
      do
         Result := def.execute_redirect(command, arguments)
      ensure
         Result /= Void
      end

   execute_to_dev_null (command, arguments: ABSTRACT_STRING): PROCESS
      require
         command /= Void
      do
         Result := def.execute_to_dev_null(command, arguments)
      ensure
         Result /= Void
      end

   execute_direct (command, arguments: ABSTRACT_STRING): PROCESS
      require
         command /= Void
      do
         Result := def.execute_direct(command, arguments)
      ensure
         Result /= Void
      end

   fork: PROCESS
      do
         Result := def.fork
      end

   split_arguments (arguments: ABSTRACT_STRING): COLLECTION[STRING]
      require
         arguments /= Void
      do
         Result := def.split_arguments(arguments)
      ensure
         Result /= Void
      end

   pid: INTEGER
      do
         Result := def.pid
      end

feature {}
   def_impl: PROCESSOR_IMPL
      once
         create Result
      end

end -- class PROCESSOR
