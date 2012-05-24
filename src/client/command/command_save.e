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
class COMMAND_SAVE

inherit
   COMMAND_WITH_REMOTE

create {CONSOLE}
   make

feature {COMMANDER}
   name: FIXED_STRING is
      once
         Result := "save".intern
      end

   help (command: COLLECTION[STRING]): STRING is
      do
         Result := once "[
                          [33msave [remote][0m      Save the password vault upto the server.
                                             [33m[remote][0m: see note below

                         ]"
      end

feature {}
   run_remote (remote: REMOTE) is
      local
         shared: SHARED
      do
         remote.save(shared.vault_file)
      end

end
