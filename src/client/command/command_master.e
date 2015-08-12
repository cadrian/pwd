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
class COMMAND_MASTER

inherit
   COMMAND

create {CONSOLE}
   make

feature {COMMANDER}
   name: FIXED_STRING
      once
         Result := ("master").intern
      end

   run (command: COLLECTION[STRING])
      local
         query: QUERY_CHANGE_MASTER; old_pass, new_pass, new_pass_confirm: STRING
      do
         if command.count /= 1 then
            error_and_help(once "Too many arguments (none expected)", command)
         else
            old_pass := client.read_password(once "Please enter the current vault password", client.on_cancel)
            if old_pass /= Void then
               new_pass := client.read_password(once "Please enter the new vault password", client.on_cancel)
               if new_pass /= Void then
                  new_pass_confirm := client.read_password(once "Please confirm the new vault password", client.on_cancel)
                  if new_pass_confirm /= Void then
                     if not new_pass.is_equal(new_pass_confirm) then
                        error_and_help(once "Passwords don't match, aborting.", command)
                     else
                        create query.make(old_pass, new_pass)
                        client.call_server(query, agent when_reply(?))
                     end
                  end
               end
            end
         end
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING]
      do
         create {FAST_ARRAY[FIXED_STRING]} Result.make(0)
      end

   help (command: COLLECTION[STRING]): STRING
      do
         Result := once "[
                    [33mmaster[0m             Change the master password.

                         ]"
      end

feature {}
   when_reply (a_reply: MESSAGE)
      local
         reply: REPLY_CHANGE_MASTER
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
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

end -- class COMMAND_MASTER
