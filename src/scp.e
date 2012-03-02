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
class SCP

inherit
   REMOTE

create {ANY}
   make

feature {ANY}
   save (local_file: ABSTRACT_STRING) is
      local
         proc: PROCESS; arg: like arguments
      do
         arg := arguments
         if arg /= Void then
            arg := once "#(1) #(2)" # local_file # arg
            proc := processor.execute(once "scp", arg)
            if proc.is_connected then
               proc.wait
            end
         end
      end

   load (local_file: ABSTRACT_STRING) is
      local
         proc: PROCESS; arg: like arguments
      do
         arg := arguments
         if arg /= Void then
            arg := once "#(1) #(2)" # arg # local_file
            proc := processor.execute(once "scp", arg)
            if proc.is_connected then
               proc.wait
            end
         end
      end

feature {}
   arguments: ABSTRACT_STRING is
      local
         file, host, user: FIXED_STRING
      do
         file := conf(config_key_remote_file)
         if file = Void then
            std_output.put_line(once "[1mMissing remote vault path![0m")
         else
            host := conf(config_key_remote_host)
            user := conf(config_key_remote_user)

            Result := file
            if host /= Void then
               Result := once "#(1):#(2)" # host # Result
               if user /= Void then
                  Result := once "#(1)@#(2)" # user # Result
               end
            elseif user /= Void then
               std_output.put_line(once "[1mSpecified user without host, ignored[0m")
            end

            Result := once "#(1) #(2)" # conf(config_key_remote_options) # Result
         end
      end

   config_key_remote_user: FIXED_STRING is
      once
         Result := "remote.user".intern
      end

   config_key_remote_host: FIXED_STRING is
      once
         Result := "remote.host".intern
      end

   config_key_remote_file: FIXED_STRING is
      once
         Result := "remote.file".intern
      end

   config_key_remote_options: FIXED_STRING is
      once
         Result := "remote.options".intern
      end

feature {}
   make is
      do
      end

end
