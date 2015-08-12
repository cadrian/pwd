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
class COMMAND_ADD

inherit
   COMMAND

create {CONSOLE}
   make

feature {COMMANDER}
   name: FIXED_STRING
      once
         Result := ("add").intern
      end

   run (command: COLLECTION[STRING])
      local
         query: QUERY_SET; pass, recipe: STRING; shared: SHARED
      do
         inspect
            command.count
         when 1 then
            create query.make_random(command.first, shared.default_recipe)
         when 2 then
            inspect
               command.last
            when "generate" then
               create query.make_random(command.first, shared.default_recipe)
            when "prompt" then
               pass := client.read_password(once "Please enter the new password for #(1)" # command.first, client.on_cancel)
               if pass /= Void then
                  create query.make_given(command.first, pass)
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
               create query.make_random(command.first, recipe)
            else
               error_and_help(once "Unrecognized argument '#(1)'" # command.last, command)
            end
         else
            error_and_help(message_invalid_arguments, command)
         end
         if query /= Void then
            client.call_server(query, agent when_reply(?))
         end
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING]
      do
         if command.count = 2 then
            Result := filter_completions(complete_how, word)
         else
            Result := no_completion
         end
      end

   help (command: COLLECTION[STRING]): STRING
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
   complete_how: ITERATOR[FIXED_STRING]
      once
         Result := {FAST_ARRAY[FIXED_STRING] << ("generate").intern, ("prompt").intern >> }.new_iterator
      end

   when_reply (a_reply: MESSAGE)
      local
         reply: REPLY_SET
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
               client.copy_to_clipboard(reply.pass)
               io.put_line(once "[1mDone[0m")
               if not client.send_save then
                  std_output.put_line(once "Failed to save the vault!")
               end
            else
               error_and_help(reply.error, Void)
            end
         else
            log.error.put_line(once "Unexpected reply")
         end
      end

end -- class COMMAND_ADD
