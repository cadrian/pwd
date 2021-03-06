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
class SCP

inherit
   REMOTE

create {ANY}
   make

feature {ANY}
   write_to (stream: OUTPUT_STREAM)
      do
         stream.put_string(once "[remote_factory]%Nmethod = scp%N%N[scp]%N")
         put_property(stream, config_key_remote_file, file)
         put_property(stream, config_key_remote_host, host)
         put_property(stream, config_key_remote_user, user)
         put_property(stream, config_key_remote_options, options)
      end

   save (local_file: ABSTRACT_STRING)
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

   load (local_file: ABSTRACT_STRING)
      local
         proc: PROCESS; arg: like arguments
      do
         arg := arguments
         if arg /= Void then
            arg := once "#(1) #(2)" # arg # local_file
            environment.set_variable(once "SSH_ASKPASS", once "true")
            proc := processor.execute(once "scp", arg)
            if proc.is_connected then
               proc.wait
            end
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
         when "host" then
            host := value.intern
            Result := True
         when "file" then
            file := value.intern
            Result := True
         when "options" then
            options := value.intern
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
         when "host" then
            host := Void
            Result := True
         when "file" then
            file := Void
            Result := True
         when "options" then
            options := Void
            Result := True
         else
            check
               not Result
            end
         end
      end

   has_proxy: BOOLEAN False

   set_proxy_property (key, value: ABSTRACT_STRING): BOOLEAN
      do
         check
            False
         end
      end

feature {}
   make (a_name: ABSTRACT_STRING)
      require
         a_name /= Void
      do
         name := a_name.intern
         specific_config := configuration.specific(name)

         file := conf(config_key_remote_file)
         host := conf(config_key_remote_host)
         user := conf(config_key_remote_user)
         options := conf(config_key_remote_options)
      ensure
         name = a_name.intern
         specific_config = configuration.specific(name)
      end

   arguments: ABSTRACT_STRING
      do
         if file = Void then
            std_output.put_line(once "[1mMissing remote vault path![0m")
         else
            Result := file
            if host /= Void then
               Result := once "#(1):#(2)" # host # Result
               if user /= Void then
                  Result := once "#(1)@#(2)" # user # Result
               end
            elseif user /= Void then
               std_output.put_line(once "[1mSpecified user without host, ignored[0m")
            end

            Result := once "#(1) #(2)" # remote_options # Result
         end
      end

   remote_options: ABSTRACT_STRING
      do
         Result := options
         if Result = Void then
            Result := once ""
         end
      ensure
         Result /= Void
      end

feature {}
   file, host, user, options: FIXED_STRING

   config_key_remote_user: FIXED_STRING
      once
         Result := ("user").intern
      end

   config_key_remote_host: FIXED_STRING
      once
         Result := ("host").intern
      end

   config_key_remote_file: FIXED_STRING
      once
         Result := ("file").intern
      end

   config_key_remote_options: FIXED_STRING
      once
         Result := ("options").intern
      end

   environment: ENVIRONMENT

   configuration_section: STRING "scp"

end -- class SCP
