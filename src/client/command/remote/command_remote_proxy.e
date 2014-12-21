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
class COMMAND_REMOTE_PROXY

inherit
   COMMAND_REMOTE_ACTION

create {COMMAND_REMOTE}
   make

feature {COMMANDER}
   name: FIXED_STRING
      once
         Result := ("proxy").intern
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING]
      do
         inspect
            command.count
         when 2 then
            Result := filter_completions(remote_map.new_iterator_on_keys, word)
         when 3 then
            Result := filter_completions(proxy_properties_or_unset, word)
         when 4 then
            inspect
               command.item(command.lower + 2)
            when "unset" then
               Result := filter_completions(proxy_properties, word)
            else
               Result := no_completion
            end
         else
            Result := no_completion
         end
      end

feature {}
   proxy_properties_: FAST_ARRAY[FIXED_STRING]
      do
         Result := {FAST_ARRAY[FIXED_STRING] << ("protocol").intern, ("host").intern, ("port").intern, ("user").intern, ("pass").intern >> }
      end

   proxy_properties: ITERATOR[FIXED_STRING]
      once
         Result := proxy_properties_.new_iterator
      end

   proxy_properties_or_unset: ITERATOR[FIXED_STRING]
      local
         p: FAST_ARRAY[FIXED_STRING]
      once
         p := proxy_properties_
         p.add_last(("unset").intern)
         Result := p.new_iterator
      end

feature {}
   run_remote (command: COLLECTION[STRING]; remote_name: FIXED_STRING; remote: REMOTE)
      do
         if remote = Void then
            error_and_help(message_unknown_remote # remote_name, command)
         elseif not remote.has_proxy then
            error_and_help(once "Cannot set proxy on that remote", command)
         elseif remote.set_proxy_property(command.first, command.last) then
            remote.save_file
         else
            error_and_help(message_property_failed, command)
         end
      end

feature {ANY}
   help (command: COLLECTION[STRING]): STRING
      do
         Result := once "[
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

                         ]"
      end

end -- class COMMAND_REMOTE_PROXY
