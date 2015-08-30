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
class CURL

inherit
   REMOTE

create {ANY}
   make

feature {ANY}
   write_to (stream: OUTPUT_STREAM)
      do
         stream.put_string(once "[remote_factory]%Nmethod = curl%N%N[curl]%N")
         put_property(stream, config_key_remote_user, user)
         put_property(stream, config_key_remote_pass, passkey)
         put_property(stream, config_key_remote_url, url)
         put_property(stream, config_key_remote_request_get, get_request)
         put_property(stream, config_key_remote_request_put, put_request)
         stream.put_string(once "%N[proxy]%N")
         put_property(stream, proxy.config_protocol, proxy.protocol)
         put_property(stream, proxy.config_host, proxy.host)
         put_property(stream, proxy.config_port, proxy.port)
         put_property(stream, proxy.config_user, proxy.user)
         put_property(stream, proxy.config_pass, proxy.passkey)
      end

   save (local_file: ABSTRACT_STRING)
      local
         proc: PROCESS; arg: like arguments
      do
         arg := arguments(once "-T", local_file, put_request)
         if arg /= Void then
            proxy.set
            proc := processor.execute(once "curl", arg)
            if proc.is_connected then
               proc.wait
            end

            proxy.reset
         end
      end

   load (local_file: ABSTRACT_STRING)
      local
         proc: PROCESS; arg: like arguments
      do
         arg := arguments(once "-o", local_file, get_request)
         if arg /= Void then
            proxy.set
            proc := processor.execute(once "curl", arg)
            if proc.is_connected then
               proc.wait
            end

            proxy.reset
         end
      end

feature {COMMAND}
   set_property (key, value: ABSTRACT_STRING): BOOLEAN
      do
         inspect
            key.out
         when "user" then
            user := value.intern
            Result := True
         when "pass" then
            passkey := value.intern
            Result := True
         when "url" then
            url := value.intern
            Result := True
         when "get_request" then
            get_request := value.intern
            Result := True
         when "put_request" then
            put_request := value.intern
            Result := True
         else
            check
               not Result
            end
         end
      end

   unset_property (key: ABSTRACT_STRING): BOOLEAN
      do
         inspect
            key.out
         when "user" then
            user := Void
            Result := True
         when "pass" then
            passkey := Void
            Result := True
         when "url" then
            url := Void
            Result := True
         when "get_request" then
            get_request := Void
            Result := True
         when "put_request" then
            put_request := Void
            Result := True
         else
            check
               not Result
            end
         end
      end

   has_proxy: BOOLEAN True

   set_proxy_property (key, value: ABSTRACT_STRING): BOOLEAN
      do
         if key.same_as(once "unset") then
            Result := proxy.unset_property(value)
         else
            Result := proxy.set_property(key, value)
         end
      end

feature {PROXY}
   get_password (key: ABSTRACT_STRING): STRING
      do
         Result := client.get_password(key)
      end

feature {}
   arguments (option, file, request: ABSTRACT_STRING): ABSTRACT_STRING
      require
         option.is_equal(once "-T") or else option.is_equal(once "-o")
         file /= Void
      local
         pass: STRING
      do
         if url = Void then
            std_output.put_line(once "[1mMissing vault url![0m")
         else
            Result := once "-\# #(1) '#(2)' '#(3)'" # option # file # url
            if not is_anonymous then
               pass := get_password(passkey)
               if pass /= Void then
                  Result := once "#(1) -u #(2):#(3)" # Result # user # pass
               end
            end

            if request /= Void then
               Result := once "#(1) --request #(2)" # Result # request
            end
         end
      end

   is_anonymous: BOOLEAN
      do
         Result := not has_conf(config_key_remote_user) or else not has_conf(config_key_remote_pass)
      end

feature {}
   url, get_request, put_request, user, passkey: FIXED_STRING

   config_key_remote_user: FIXED_STRING
      once
         Result := ("user").intern
      end

   config_key_remote_pass: FIXED_STRING
      once
         Result := ("pass").intern
      end

   config_key_remote_url: FIXED_STRING
      once
         Result := ("url").intern
      end

   config_key_remote_request_get: FIXED_STRING
      once
         Result := ("request.get").intern
      end

   config_key_remote_request_put: FIXED_STRING
      once
         Result := ("request.put").intern
      end

feature {}
   make (a_name: ABSTRACT_STRING; a_client: like client)
      require
         a_name /= Void
         a_client /= Void
      do
         name := a_name.intern
         specific_config := configuration.specific(name)
         client := a_client
         create proxy.make(Current)

         url := conf(config_key_remote_url)
         passkey := conf(config_key_remote_pass)
         user := conf(config_key_remote_user)
         get_request := conf(config_key_remote_request_get)
         put_request := conf(config_key_remote_request_put)
      ensure
         name = a_name.intern
         specific_config = configuration.specific(name)
         client = a_client
      end

   client: CLIENT

   proxy: PROXY

invariant
   client /= Void --proxy /= Void

end -- class CURL
