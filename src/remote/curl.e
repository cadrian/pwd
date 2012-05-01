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
class CURL

inherit
   REMOTE

create {ANY}
   make

feature {ANY}
   save (local_file: ABSTRACT_STRING) is
      local
         proc: PROCESS; arg: like arguments
      do
         arg := arguments(once "-T", local_file, config_key_remote_request_put)
         if arg /= Void then
            proc := processor.execute(once "curl", arg)
            if proc.is_connected then
               proc.wait
            end
         end
      end

   load (local_file: ABSTRACT_STRING) is
      local
         proc: PROCESS; arg: like arguments
      do
         arg := arguments(once "-o", local_file, config_key_remote_request_get)
         if arg /= Void then
            proc := processor.execute(once "curl", arg)
            if proc.is_connected then
               proc.wait
            end
         end
      end

feature {}
   arguments (option, file, config_request: ABSTRACT_STRING): ABSTRACT_STRING is
      require
         option.is_equal(once "-T") or else option.is_equal(once "-o")
         file /= Void
      local
         pass: STRING
         url, request: FIXED_STRING
      do
         url := conf(config_key_remote_url)
         if url = Void then
            std_output.put_line(once "[1mMissing vault url![0m")
         else
            Result := once "-\# #(1) '#(2)' '#(3)'" # option # file # url
            if not is_anonymous then
               pass := client.get_password(conf(config_key_remote_pass))
               if pass /= Void then
                  Result := once "#(1) -u #(2):#(3)" # Result # conf(config_key_remote_user) # pass
               end
            end
            request := conf(config_request)
            if request /= Void then
               Result := once "#(1) --request #(2)" # Result # request
            end
         end
      end

   is_anonymous: BOOLEAN is
      do
         Result := not has_conf(config_key_remote_user) or else not has_conf(config_key_remote_pass)
      end

   config_key_remote_user: FIXED_STRING is
      once
         Result := "remote.user".intern
      end

   config_key_remote_pass: FIXED_STRING is
      once
         Result := "remote.pass".intern
      end

   config_key_remote_url: FIXED_STRING is
      once
         Result := "remote.url".intern
      end

   config_key_remote_request_get: FIXED_STRING is
      once
         Result := "remote.request.get".intern
      end

   config_key_remote_request_put: FIXED_STRING is
      once
         Result := "remote.request.put".intern
      end

feature {}
   make (a_client: like client) is
      require
         a_client /= Void
      do
         client := a_client
      ensure
         client = a_client
      end

   client: CLIENT

invariant
   client /= Void

end
