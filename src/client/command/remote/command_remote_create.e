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
class COMMAND_REMOTE_CREATE

inherit
   COMMAND_REMOTE_ACTION

create {COMMAND_REMOTE}
   make

feature {COMMANDER}
   name: FIXED_STRING is
      once
         Result := "create".intern
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING] is
      do
         Result := no_completion
      end

feature {}
   run_remote (command: COLLECTION[STRING]; remote_name: FIXED_STRING; remote: REMOTE) is
      local
         remote_factory: REMOTE_FACTORY
         new_remote: REMOTE
      do
         if remote /= Void then
            error_and_help(once "Duplicate remote: #(1)" # remote_name, command)
         elseif not command.first.same_as(once "method") then
            error_and_help(once "Unknown command: #(1)" # command.first, command)
         elseif remote_name.same_as(once "config") then
            error_and_help(once "This name (#(1)) is reserved, please choose another one" # remote_name, command)
         else
            new_remote := remote_factory.new_remote(remote_name, command.last, client)
            if new_remote /= Void then
               new_remote.save_file
               remote_map.add(new_remote, remote_name)
            end
         end
      end

feature {ANY}
   help (command: COLLECTION[STRING]): STRING is
      do
         Result := once "[
                          [33mremote create [remote] method {curl|scp}[0m
                                             Create a new remote. Give it a name and choose a method.

                         ]"
      end

end
