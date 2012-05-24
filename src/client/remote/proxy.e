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
class PROXY

insert
   LOGGING
   CONFIGURABLE

create {REMOTE}
   make

feature {REMOTE}
   is_set: BOOLEAN

   set is
      require
         not is_set
      local
         sys: SYSTEM; url: like proxy_url
      do
         url := proxy_url
         if url /= Void then
            sys.set_environment_variable(once "ALL_PROXY", url.out)
            log.trace.put_line(once "Proxy set.")
            is_set := True
         end
      end

   reset is
      local
         sys: SYSTEM
      do
         if is_set then
            sys.set_environment_variable(once "ALL_PROXY", once "")
            log.trace.put_line(once "Proxy unset.")
            is_set := False
         end
      ensure
         not is_set
      end

   set_property (key, value: ABSTRACT_STRING): BOOLEAN is
      do
         inspect
            key.out
         when "protocol" then
            protocol := value.intern
            Result := True
         when "host" then
            host := value.intern
            Result := True
         when "port" then
            port := value.intern
            Result := True
         when "user" then
            user := value.intern
            Result := True
         when "pass" then
            passkey := value.intern
            Result := True
         else
            check not Result end
         end
      end

   unset_property (key: ABSTRACT_STRING): BOOLEAN is
      do
         inspect
            key.out
         when "protocol" then
            protocol := Void
            Result := True
         when "host" then
            host := Void
            Result := True
         when "port" then
            port := Void
            Result := True
         when "user" then
            user := Void
            Result := True
         when "pass" then
            passkey := Void
            Result := True
         else
            check not Result end
         end
      end

feature {}
   proxy_url: ABSTRACT_STRING is
      require
         remote /= Void
      local
         pass: STRING
      do
         if host = Void then
            log.info.put_line(once "No defined proxy.")
         else
            log.trace.put_line(once "Installing proxy: host=#(1)" # host)

            if protocol /= Void then
               log.trace.put_line(once "                  protocol=#(1)" # protocol)
            end
            if port /= Void then
               log.trace.put_line(once "                  port=#(1)" # port)
            end
            if user /= Void then
               log.trace.put_line(once "                  user=#(1)" # user)
            end
            if pass /= Void then
               log.trace.put_line(once "                  pass=#(1)" # pass)
               pass := remote.get_password(pass)
            end

            if user = Void then
               Result := host
            else
               if pass = Void then
                  Result := "#(1)@#(2)" # user # host
               else
                  Result := "#(1):#(2)@#(3)" # user # escape(pass) # host
               end
            end

            if port /= Void then
               Result := "#(1):#(2)" # Result # port
            end
            if protocol /= Void then
               Result := "#(1)://#(2)" # protocol # Result
            end
         end
      end

   escape (pass: STRING): STRING is
      local
         i: INTEGER; c: CHARACTER
      do
         create Result.with_capacity(pass.count)
         from
            i := pass.lower
         variant
            pass.upper - i
         until
            i > pass.upper
         loop
            c := pass.item(i)
            inspect
               c
            when '%%' then
               Result.append(once "%%25")
            when ':' then
               Result.append(once "%%3A")
            when '@' then
               Result.append(once "%%40")
            else
               Result.extend(c)
            end
            i := i + 1
         end
      end

feature {}
   make (a_remote: like remote) is
      require
         a_remote /= Void
      do
         remote := a_remote
         specific_config := configuration.specific(a_remote.name)

         protocol := conf(config_protocol)
         host := conf(config_host)
         port := conf(config_port)
         user := conf(config_user)
         passkey := conf(config_pass)
      ensure
         remote = a_remote
         specific_config = configuration.specific(a_remote.name)
      end

   remote: CURL

feature {REMOTE}
   protocol, host, port, user, passkey: FIXED_STRING

   config_protocol: FIXED_STRING is
      once
         Result := "protocol".intern
      end

   config_host: FIXED_STRING is
      once
         Result := "host".intern
      end

   config_port: FIXED_STRING is
      once
         Result := "port".intern
      end

   config_user: FIXED_STRING is
      once
         Result := "user".intern
      end

   config_pass: FIXED_STRING is
      once
         Result := "pass".intern
      end

invariant
   remote /= Void
   specific_config /= Void

end
