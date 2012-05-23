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
class COMMAND_REMOTE

inherit
   COMMAND

create {CLIENT}
   make

feature {CLIENT}
   name: FIXED_STRING is
      once
         Result := "remote".intern
      end

   run (command: COLLECTION[STRING]) is
      local
         subcmd, name: STRING; count: INTEGER
         remote: REMOTE
         action: PROCEDURE[TUPLE[REMOTE, FIXED_STRING]]
      do
         if command.count < 2 then
            std_output.put_line(once "[1mNot enough arguments![0m")
         else
            subcmd := command.first
            command.remove_first
            name := command.first
            command.remove_first

            remote := remote_map.fast_reference_at(name.intern)
            inspect
               subcmd
            when "create" then
               count := 2
               action := agent remote_create
            when "delete" then
               count := 0
               action := agent remote_delete
            when "unset" then
               count := 1
               action := agent remote_unset
            when "set" then
               count := 2
               action := agent remote_set
            when "proxy" then
               count := 2
               action := agent remote_proxy
            else
               std_output.put_line(once "[1mUnknown sub-command: #(1)[0m" # subcmd)
            end

            if command.count < count then
               std_output.put_line(once "[1mNot enough arguments![0m")
            elseif action /= Void then
               if command.count > count then
                  std_output.put_line(once "[1mIgnoring extra arguments[0m")
               end
               action.call([remote, name.intern])
            end
         end
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING] is
      do
         create {FAST_ARRAY[FIXED_STRING]} Result.make(0)
      end

feature {}
   remote_create (remote: REMOTE; name: FIXED_STRING) is
      local
         remote_factory: REMOTE_FACTORY
         new_remote: REMOTE
      do
         if remote /= Void then
            std_output.put_line(once "[1mDuplicate remote: #(1)[0m" # name)
         elseif not command.first.same_as(once "method") then
            std_output.put_line(once "[1mUnknown command: #(1)[0m" # command.first)
         elseif name.same_as(once "config") then
            std_output.put_line(once "[1mThis name (#(1)) is reserved, please choose another one[0m" # name)
         else
            new_remote := remote_factory.new_remote(name, command.last, Current)
            if new_remote /= Void then
               new_remote.save_file
               remote_map.add(new_remote, name)
            end
         end
      end

   remote_delete (remote: REMOTE; name: FIXED_STRING) is
      do
         if remote = Void then
            std_output.put_line(once "[1mUnknown remote: #(1)[0m" # name)
         else
            remote.delete_file
            remote_map.fast_remove(remote.name)
         end
      end

   remote_unset (remote: REMOTE; name: FIXED_STRING) is
      do
         if remote = Void then
            std_output.put_line(once "[1mUnknown remote: #(1)[0m" # name)
         elseif remote.unset_property(command.first) then
            remote.save_file
         else
            std_output.put_line(once "[1mFailed (unknown property?)[0m")
         end
      end

   remote_set (remote: REMOTE; name: FIXED_STRING) is
      do
         if remote = Void then
            std_output.put_line(once "[1mUnknown remote: #(1)[0m" # name)
         elseif remote.set_property(command.first, command.last) then
            remote.save_file
         else
            std_output.put_line(once "[1mFailed (unknown property?)[0m")
         end
      end

   remote_proxy (remote: REMOTE; name: FIXED_STRING) is
      do
         if remote = Void then
            std_output.put_line(once "[1mUnknown remote: #(1)[0m" # name)
         elseif not remote.has_proxy then
            std_output.put_line(once "[1mCannot set proxy on that remote[0m")
         elseif remote.set_proxy_property(command.first, command.last) then
            remote.save_file
         else
            std_output.put_line(once "[1mFailed (unknown property?)[0m")
         end
      end

feature {ANY}
   help (command: COLLECTION[STRING]): ABSTRACT_STRING is
         -- If `command' is Void, provide extended help
         -- Otherwise provide help depending on the user input
      do
         Result := once "[
                    [33mremote create [remote] method {curl|scp}[0m
                                       Create a new remote. Give it a name and choose a method.

                    [33mremote delete [remote][0m
                                       Delete a remote.
                                       [33m[remote][0m: see note below

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

                    [33mremote unset [remote] [property][0m
                                       Unset a property of a remote.
                                       [33m[remote][0m: see note below

                    [33mremote proxy [remote] [property] [value][0m
                                       Set a property of the proxy attached to a remote.
                                       The properties are:
                                         - [33mprotocol[0m    the proxy protocol (default http)
                                         - [33mhost[0m        the proxy host (must be set for the proxy
                                                       to be used)
                                         - [33mport[0m        the proxy port
                                         - [33muser[0m        the proxy user
                                         - [33mpass[0m        the key of the proxy password in the vault
                                       [33m[remote][0m: see note below

                    [33mremote proxy [remote] unset [property][0m
                                       Unset a property of the proxy attached to a remote.
                                       [33m[remote][0m: see note below

                                     [1;33m|[0m [33m[remote][0m note:
                                     [1;33m|[0m The [33mload[0m, [33msave[0m, [33mmerge[0m, and [33mremote[0m commands require
                                     [1;33m|[0m an extra argument if there is more than one available
                                     [1;33m|[0m remotes.
                                     [1;33m|[0m In that case, the argument is the remote to select.
                                     [1;33m|[0m
                                     [1;33m|[0m #(1)

                         ]" # help_list_remotes
      end

end
