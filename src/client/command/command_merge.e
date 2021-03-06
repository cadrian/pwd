-- This file is part of pwd.
-- Copyright (C) 2012-2015 Cyril Adrian <cyril.adrian@gmail.com>
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
class COMMAND_MERGE

inherit
   COMMAND_WITH_REMOTE

create {CONSOLE}
   make

feature {COMMANDER}
   name: FIXED_STRING
      once
         Result := ("merge").intern
      end

   help (command: COLLECTION[STRING]): STRING
      do
         Result := once "[
                          [33mmerge [remote][0m     Load the server version and compare to the local one.
                                             Keep the most recent keys and save the merged version
                                             back to the server.
                                             [33m[remote][0m: see note below

                         ]"
      end

feature {}
   run_remote (remote: REMOTE)
      local
         merge_pass0, merge_pass: STRING; shared: SHARED
      do
         remote.load(merge_vault)
         merge_pass0 := client.read_password(once "Please enter the encryption phrase%Nto the remote vault%N(just leave empty if the same as the current vault's)", client.on_cancel)
         if merge_pass0 = Void then
            -- cancelled
         else
            if merge_pass0.is_empty then
               merge_pass := client.master_pass
            else
               merge_pass := once ""
               merge_pass.copy(merge_pass0)
            end
            client.call_server(create {QUERY_MERGE}.make(merge_vault, merge_pass), agent when_reply(?))
            if client.send_save then
               remote.save(shared.vault_file)
            else
               std_output.put_line(once "Failed to save the vault!")
            end
         end

         filesystem.delete(merge_vault)
      end

   merge_vault: FIXED_STRING
      once
         Result := ("#(1)/merge_vault" # client.tmpdir).intern
      end

   when_reply (a_reply: MESSAGE)
      local
         reply: REPLY_MERGE
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
               client.copy_to_clipboard(once "")
               io.put_line(once "[1mDone[0m")
            else
               error_and_help(reply.error, Void)
            end
         else
            log.error.put_line(once "Unexpected reply")
         end
      end

   filesystem: FILESYSTEM

end -- class COMMAND_MERGE
