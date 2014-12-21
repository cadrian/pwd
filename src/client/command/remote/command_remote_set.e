-- This file is part of pwd.
-- Copyright (C) 2012-2014 Cyril Adrian <cyril.adrian@gmail.com>
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
class COMMAND_REMOTE_SET

inherit
   COMMAND_REMOTE_ACTION

create {COMMAND_REMOTE}
   make

feature {COMMANDER}
   name: FIXED_STRING
      once
         Result := ("set").intern
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING]
      do
         inspect
            command.count
         when 2 then
            Result := filter_completions(remote_map.new_iterator_on_keys, word)
         when 3 then
            -- TODO
            Result := no_completion
         else
            Result := no_completion
         end
      end

feature {}
   run_remote (command: COLLECTION[STRING]; remote_name: FIXED_STRING; remote: REMOTE)
      do
         if remote = Void then
            error_and_help(message_unknown_remote # remote_name, command)
         elseif remote.set_property(command.first, command.last) then
            remote.save_file
         else
            error_and_help(message_property_failed, command)
         end
      end

feature {ANY}
   help (command: COLLECTION[STRING]): STRING
      do
         Result := once "[
                    [33mremote set [remote] [property] [value][0m
                                       Set a property of a remote.
                                       The properties are:
                                         - [33muser[0m        the user name
                                       * curl specific:
                                         - [33mpass[0m        the key of the password in the vault
                                         - [33murl[0m         the url of the remote vault file
                                                       (not directory)
                                         - [33mget_request[0m the http get verb (e.g. GET or PROPFIND)
                                         - [33mset_request[0m the http put verb (e.g. PUT)
                                       * scp specific:
                                         - [33mhost[0m        the hostname
                                         - [33mfile[0m        the path of the remote vault file
                                                       (not directory)
                                         - [33moptions[0m     the scp options
                                       [33m[remote][0m: see note below

                         ]"
      end

end -- class COMMAND_REMOTE_SET
