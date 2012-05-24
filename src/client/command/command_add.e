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

create {CONSOLE}
   make

feature {COMMANDER}
   name: FIXED_STRING is
      once
         Result := "add".intern
      end

   run (command: COLLECTION[STRING]) is
      local
         cmd: ABSTRACT_STRING; pass, recipe: STRING
         shared: SHARED
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
               pass := client.read_password(once "Please enter the new password for #(1)" # command.first, client.on_cancel)
               if pass /= Void then
                  cmd := once "#(1) given #(2)" # command.first # pass
               end
            else
               error_and_help(once "Unrecognized argument '#(1)'" # command.last, command)
            end
         when 3 then
            recipe := command.last
            command.remove_last
            inspect
               command.last
            when "generate" then
               cmd := once "#(1) random #(2)" # command.first # recipe
            else
               error_and_help(once "Unrecognized argument '#(1)'" # command.last, command)
            end
         else
            error_and_help(message_invalid_arguments, command)
         end
         if cmd /= Void then
            client.call_server(once "set", cmd,
                               agent (stream: INPUT_STREAM) is
                               do
                                  stream.read_line
                                  if not stream.end_of_input then
                                     data.clear_count
                                     stream.last_string.split_in(data)
                                     if data.count = 2 then
                                        client.xclip(data.last)
                                     else
                                        check data.count = 1 end
                                        client.xclip(once "")
                                        error_and_help(once "Server protocol error", Void)
                                     end
                                  end
                               end)
            client.send_save
         end
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING] is
      do
         if command.count = 2 then
            Result := filter_completions(complete_how, word)
         else
            Result := no_completion
         end
      end

   help (command: COLLECTION[STRING]): STRING is
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

feature {}
   complete_how: ITERATOR[FIXED_STRING] is
      once
         Result := {FAST_ARRAY[FIXED_STRING] <<
            "generate".intern,
            "prompt".intern,
         >> }.new_iterator
      end

end
