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
class ENCRYPTED_IO

inherit
   VAULT_IO

insert
   LOGGING
   CONFIGURABLE

create {ANY}
   make

feature {ANY}
   exists: BOOLEAN then nested.exists end

   load (loader: FUNCTION[TUPLE[INPUT_STREAM], ABSTRACT_STRING]): ABSTRACT_STRING
      do
         Result := nested.load(agent decrypt(loader, ?))
      end

   save (saver: FUNCTION[TUPLE[OUTPUT_STREAM], ABSTRACT_STRING]; on_save: FUNCTION[TUPLE[ABSTRACT_STRING], ABSTRACT_STRING]): ABSTRACT_STRING
      local
         proc: PROCESS; proc_out: INPUT_STREAM
      do
         proc := processor.execute_redirect(once "openssl", once "#(1) -a -pass env:VAULT_MASTER" # conf(config_openssl_cipher))
         if proc.is_connected then
            Result := saver.item([proc.input])
            proc.input.flush
            proc.input.disconnect
            proc_out := proc.output
            Result := nested.save(agent (p_in: INPUT_STREAM; p_out: OUTPUT_STREAM): ABSTRACT_STRING
                                     do
                                        extern.splice(p_in, p_out)
                                        Result := once ""
                                     end (proc_out, ?),
                                  agent on_encrypt(proc, ?))
         else
            Result := once "could not execute openssl"
         end
         Result := on_save.item([Result])
      end

   is_open: BOOLEAN
      do
         Result := is_open_ and then nested.is_open
      end

   close
      do
         nested.close
         if is_open_ then
            environment.set_variable(once "VAULT_MASTER", once "")
            is_open_ := False
         end
      end

feature {}
   decrypt (ldr: FUNCTION[TUPLE[INPUT_STREAM], ABSTRACT_STRING]; in: INPUT_STREAM): ABSTRACT_STRING
      local
         proc: PROCESS
      do
         proc := processor.execute_redirect(once "openssl", once "#(1) -d -a -pass env:VAULT_MASTER" # conf(config_openssl_cipher))
         if proc.is_connected then
            extern.splice(in, proc.input)
            proc.input.disconnect
            Result := ldr.item([proc.output])
            proc.wait
            if proc.status = 0 then
               Result := once ""
            else
               Result := once "openssl exited with status #(1)" # proc.status.out
            end
         else
            Result := once "could not execute openssl"
         end
      end

   on_encrypt (proc: PROCESS; res: ABSTRACT_STRING): ABSTRACT_STRING
      do
         proc.wait
         if proc.status = 0 then
            Result := res
         else
            Result := once "openssl failed with status #(1)" # proc.status.out
            if not res.is_empty then
               Result := "#(1); #(2)" # res # Result
            end
         end
      end

   make (master: STRING; a_nested: like nested)
      require
         master /= Void
         a_nested /= Void
      do
         nested := a_nested
         environment.set_variable(once "VAULT_MASTER", master)
         is_open_ := True
      ensure
         nested = a_nested
         is_open_
      end

   nested: VAULT_IO
   is_open_: BOOLEAN

   processor: PROCESSOR
   extern: EXTERN
   environment: ENVIRONMENT

   config_openssl_cipher: FIXED_STRING
      once
         Result := ("openssl.cipher").intern
      end

   configuration_section: STRING "vault"

end -- class ENCRYPTED_IO
