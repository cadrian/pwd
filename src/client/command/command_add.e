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
class COMMAND_ADD

inherit
   COMMAND

create {CLIENT}
   make

feature {CLIENT}
   name: FIXED_STRING is
      once
         Result := "add".intern
      end

   run (command: COLLECTION[STRING]) is
      local
         cmd: ABSTRACT_STRING; pass, recipe: STRING
      do
         inspect
            command.count
         when 1 then
            cmd := once "#(1) random #(2)" # command.first # shared.default_recipe
         when 2 then
            inspect
               command.last
            when "generate" then
               cmd := once "#(1) random #(2)" # command.first # shared.default_recipe
            when "prompt" then
               pass := read_password(once "Please enter the new password for #(1)" # command.first, on_cancel)
               if pass /= Void then
                  cmd := once "#(1) given #(2)" # command.first # pass
               end
            else
               io.put_line(once "[1mError:[0m unrecognized argument '#(1)'" # command.last)
            end
         when 3 then
            recipe := command.last
            command.remove_last
            inspect
               command.last
            when "generate" then
               cmd := once "#(1) random #(2)" # command.first # recipe
            else
               io.put_line(once "[1mError:[0m unrecognized argument '#(1)'" # command.last)
            end
         else
            io.put_line(once "[1mError:[0m bad number of arguments")
         end
         if cmd /= Void then
            call_server(once "set", cmd,
                        agent (stream: INPUT_STREAM) is
                           do
                              stream.read_line
                              if not stream.end_of_input then
                                 data.clear_count
                                 stream.last_string.split_in(data)
                                 if data.count = 2 then
                                    xclip(data.last)
                                 else
                                    check data.count = 1 end
                                    xclip(once "")
                                    io.put_line(once "[1mError[0m") -- ???
                                 end
                              end
                           end)
            send_save
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
                    [33madd <key> [how][0m    Add a new password. Needs at least a key.
                                       If [33m[how][0m is "generate" then the password is
                                       randomly generated ([1mdefault[0m).
                                       If [33m[how][0m is "generate" with an extra argument then
                                       the extra argument represents a "recipe" used to generate
                                       the password (*).
                                       If [33m[how][0m is "prompt" then the password is asked.
                                       If the password already exists it is changed.
                                       In all cases the password is stored in the clipboard.

                                       (*) A recipe is a series of "ingredients" separated by a '+'.
                                       Each "ingredient" is an optional quantity (default 1)
                                       followed by a series of 'a' (alphanumeric), 'n' (numeric),
                                       or 's' (symbol).
                                       The password is generated using the recipe to randomly select
                                       characters, and mixing them.

                         ]"
      end

end
