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
   COMMAND

create {CLIENT}
   make

feature {CLIENT}
   name: FIXED_STRING is
      once
         Result := "merge".intern
      end

   run (command: COLLECTION[STRING]) is
      local
         merge_pass0, merge_pass: STRING
         remote: REMOTE
      do
         remote := selected_remote
         if remote /= Void then
            std_output.put_line(once "[32mPlease wait...[0m")
            remote.load(merge_vault)

            merge_pass0 := read_password(once "Please enter the encryption phrase%Nto the remote vault%N(just leave empty if the same as the current vault's)", on_cancel)
            if merge_pass0 = Void then
               -- cancelled
            else
               if merge_pass0.is_empty then
                  merge_pass := master_pass
               else
                  merge_pass := once ""
                  merge_pass.copy(merge_pass0)
               end
               call_server(once "merge", once "#(1) #(2)" # merge_vault # merge_pass,
                           agent (stream: INPUT_STREAM) is
                              do
                                 stream.read_line
                                 if not stream.end_of_input then
                                    xclip(once "")
                                    io.put_line(once "[1mDone[0m")
                                 end
                              end)
               send_save
               remote.save(shared.vault_file)
            end

            delete(merge_vault)
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
                    [33mmerge [remote][0m     Load the server version and compare to the local one.
                                       Keep the most recent keys and save the merged version
                                       back to the server.
                                       [33m[remote][0m: see note below

                         ]"
      end

end
