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
class COMMAND_MERGE

inherit
   COMMAND_WITH_REMOTE

insert
   FILE_TOOLS

create {CONSOLE}
   make

feature {COMMANDER}
   name: FIXED_STRING is
      once
         Result := "merge".intern
      end

   help (command: COLLECTION[STRING]): STRING is
      do
         Result := once "[
                          [33mmerge [remote][0m     Load the server version and compare to the local one.
                                             Keep the most recent keys and save the merged version
                                             back to the server.
                                             [33m[remote][0m: see note below

                         ]"
      end

feature {}
   run_remote (remote: REMOTE) is
      local
         merge_pass0, merge_pass: STRING
         shared: SHARED
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
            client.call_server(once "merge", once "#(1) #(2)" # merge_vault # merge_pass,
                               agent (stream: INPUT_STREAM) is
                                  do
                                     stream.read_line
                                     if not stream.end_of_input then
                                        client.xclip(once "")
                                        io.put_line(once "[1mDone[0m")
                                     end
                                  end)
            client.send_save
            remote.save(shared.vault_file)
         end

         delete(merge_vault)
      end

   merge_vault: FIXED_STRING is
      once
         Result := ("#(1)/merge_vault" # client.tmpdir).intern
      end

end