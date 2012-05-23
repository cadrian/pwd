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
   COMMAND

create {CLIENT}
   make

feature {CLIENT}
   name: FIXED_STRING is
      once
         Result := "save".intern
      end

   run (command: COLLECTION[STRING]) is
      local
         remote: REMOTE
      do
         remote := selected_remote
         if remote /= Void then
            std_output.put_line(once "[32mPlease wait...[0m")
            remote.save(shared.vault_file)
         end
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING] is
      do
         create {FAST_ARRAY[FIXED_STRING]} Result.make(0)
      end

feature {ANY}
   help (command: COLLECTION[STRING]): STRING is
         -- If `command' is Void, provide extended help
         -- Otherwise provide help depending on the user input
      do
         Result := once "[
                    [33msave [remote][0m      Save the password vault upto the server.
                                       [33m[remote][0m: see note below

                         ]"
      end

end
