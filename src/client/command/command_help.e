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
class COMMAND_HELP

inherit
   COMMAND
      redefine
         make
      end

insert
   COMMANDER

create {CONSOLE}
   make

feature {COMMANDER}
   name: FIXED_STRING is
      once
         Result := "help".intern
      end

   run (command: COLLECTION[STRING]) is
      local
         msg: STRING
      do
         if not command.is_empty then
            error_and_help(message_invalid_arguments, command)
         else
            msg := once ""
            msg.copy(once "[1;32mKnown commands[0m%N")
            add_help(msg)
            msg.append(once "[

                             Any other input is understood as a password request using the given key.
                             If that key exists the password is stored in the clipboard.

                             [1m--------[0m
                             [32mpwdmgr Copyright (C) 2012 Cyril Adrian <cyril.adrian@gmail.com>[0m
                             [32mThis program comes with ABSOLUTELY NO WARRANTY; for details type [33mshow w[32m.[0m
                             [32mThis is free software, and you are welcome to redistribute it[0m
                             [32munder certain conditions; type [33mshow c[32m for details.[0m

                             ]")

            client.less(msg)
         end
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING] is
      do
         Result := filter_completions(commands.new_iterator_on_keys, word)
      end

   help (command: COLLECTION[STRING]): STRING is
      do
         Result := once "[33mhelp[0m               Show this screen"
      end

feature {}
   make (a_client: like client; a_map: DICTIONARY[COMMAND, FIXED_STRING]) is
      do
         Precursor(a_client, a_map)
         commands := a_map
      ensure then
         commands = a_map
      end

end
