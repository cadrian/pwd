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
class COMMAND_MASTER

inherit
   COMMAND

create {CONSOLE}
   make

feature {COMMANDER}
   name: FIXED_STRING is
      once
         Result := "master".intern
      end

   run (command: COLLECTION[STRING]) is
      do
         error_and_help(once "Not yet implemented", command)
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING] is
      do
         create {FAST_ARRAY[FIXED_STRING]} Result.make(0)
      end

   help (command: COLLECTION[STRING]): STRING is
      do
         Result := once "[
                    [33mmaster[0m             Change the master password.
                                       [1m(not yet implemented)[0m

                         ]"
      end

end
