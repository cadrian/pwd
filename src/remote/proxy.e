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
   set is
      local
         sys: SYSTEM
      do
         if proxy_url /= Void then
            sys.set_environment_variable(once "ALL_PROXY", proxy_url.out)
            log.trace.put_line(once "Proxy set.")
         end
      end

   reset is
      local
         sys: SYSTEM
      do
         if proxy_url /= Void then
            sys.set_environment_variable(once "ALL_PROXY", once "")
            log.trace.put_line(once "Proxy unset.")
         end
      end

feature {}
   proxy_url: ABSTRACT_STRING

   parse is
      require
         remote /= Void
      local
         protocol, host, port, user, pass: FIXED_STRING
         pwd: STRING
      do
         host := conf(config_host)

         if host = Void then
            log.info.put_line(once "No defined proxy.")
         else
            log.trace.put_line(once "Installing proxy: host=#(1)" # host)

            protocol := conf(config_protocol)
            if protocol /= Void then
               log.trace.put_line(once "                  protocol=#(1)" # protocol)
            end
            port := conf(config_port)
            if port /= Void then
               log.trace.put_line(once "                  port=#(1)" # port)
            end
            user := conf(config_user)
            if user /= Void then
               log.trace.put_line(once "                  user=#(1)" # user)
            end
            pass := conf(config_pass)
            if pass /= Void then
               log.trace.put_line(once "                  pass=#(1)" # pass)
               pwd := remote.get_password(pass)
            end

            if user = Void then
               proxy_url := host
            else
               if pwd = Void then
                  proxy_url := "#(1)@#(2)" # user # host
               else
                  proxy_url := "#(1):#(2)@#(3)" # user # escape(pwd) # host
               end
            end

            if port /= Void then
               proxy_url := "#(1):#(2)" # proxy_url # port
            end
            if protocol /= Void then
               proxy_url := "#(1)://#(2)" # protocol # proxy_url
            end
         end
      end

   escape (pwd: STRING): STRING is
      local
         i: INTEGER; c: CHARACTER
      do
         create Result.with_capacity(pwd.count)
         from
            i := pwd.lower
         variant
            pwd.upper - i
         until
            i > pwd.upper
         loop
            c := pwd.item(i)
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

feature {}
   make (a_remote: like remote) is
      require
         a_remote /= Void
      do
         remote := a_remote
         specific_config := configuration.specific(a_remote.name)
         parse
      ensure
         remote = a_remote
         specific_config = configuration.specific(a_remote.name)
      end

   remote: CURL

invariant
   remote /= Void
   specific_config /= Void

end
