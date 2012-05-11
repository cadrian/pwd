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
expanded class PROXY

insert
   LOGGING
   CONFIGURABLE

feature {CLIENT}
   install (client: CLIENT) is
      require
         client /= Void
      local
         sys: SYSTEM
         protocol, host, port, user, pass: FIXED_STRING
         pwd: STRING
         proxy_url: ABSTRACT_STRING
      do
         host := conf(config_host)

         if host = Void then
            log.info.put_line(once "No defined proxy.")
         else
            log.trace.put_line(once "Installing proxy: host=#(1)" # host)

            protocol := conf(config_protocol)
            log.trace.put_line(once "                  protocol=#(1)" # protocol)
            port := conf(config_port)
            log.trace.put_line(once "                  port=#(1)" # port)
            user := conf(config_user)
            log.trace.put_line(once "                  user=#(1)" # user)
            pass := conf(config_pass)
            log.trace.put_line(once "                  pass=#(1)" # pass)
            if pass /= Void then
               pwd := client.get_password(pass)
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

            sys.set_environment_variable(once "ALL_PROXY", proxy_url.out)
            log.info.put_line(once "Proxy installed.")
         end
      end

feature {}
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

end
