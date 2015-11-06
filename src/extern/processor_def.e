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
deferred class PROCESSOR_DEF

inherit
   TESTABLE

feature {PROCESSOR}
   execute (command, arguments: ABSTRACT_STRING): PROCESS
      require
         command /= Void
      deferred
      ensure
         Result /= Void
      end

   execute_redirect (command, arguments: ABSTRACT_STRING): PROCESS
      require
         command /= Void
      deferred
      ensure
         Result /= Void
      end

   execute_to_dev_null (command, arguments: ABSTRACT_STRING): PROCESS
      require
         command /= Void
      deferred
      ensure
         Result /= Void
      end

   execute_direct (command, arguments: ABSTRACT_STRING): PROCESS
      require
         command /= Void
      deferred
      ensure
         Result /= Void
      end

   fork: PROCESS
      deferred
      end

   split_arguments (arguments: ABSTRACT_STRING): COLLECTION[STRING]
      require
         arguments /= Void
      deferred
      ensure
         Result /= Void
      end

   pid: INTEGER
      deferred
      end

end -- class PROCESSOR_DEF
