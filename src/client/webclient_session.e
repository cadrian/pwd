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
class WEBCLIENT_SESSION
   --
   -- Low-level management of a pwdclient session
   --

insert
   LOGGING
   DISPOSABLE
   STRING_HANDLER

create {WEBCLIENT}
   make

feature {WEBCLIENT}
   get_auth_token (action: PROCEDURE[TUPLE[FIXED_STRING, FIXED_STRING]]; on_error: PROCEDURE[TUPLE[ABSTRACT_STRING]])
         -- action takes the old and new auth tokens
      require
         is_available
      do
         if old_token /= Void then
            next_auth_token(agent (ot, nt: FIXED_STRING; a: PROCEDURE[TUPLE[FIXED_STRING, FIXED_STRING]])
                               do
                                  action.call([ot, nt])
                               end(old_token.intern, ?, action),
                            on_error)
         else
            old_token := token
            if old_token /= Void then
               debug
                  log.trace.put_line("**** Old token was: #(1)" # old_token)
               end
               --|**** TODO (Liberty Eiffel) I would have liked to write:
               -- next_auth_token(agent action(old_token, ?))
               next_auth_token(agent (ot, nt: FIXED_STRING; a: PROCEDURE[TUPLE[FIXED_STRING, FIXED_STRING]])
                                  do
                                     action.call([ot, nt])
                                  end(old_token.intern, ?, action),
                               on_error)
            else
               on_error.call(["Old token not found"])
            end
         end
      end

   next_auth_token (action: PROCEDURE[TUPLE[FIXED_STRING]]; on_error: PROCEDURE[TUPLE[ABSTRACT_STRING]])
         -- action takes the new auth token
      require
         is_available
      do
         if new_token /= Void then
            action.call([new_token.intern])
         else
            log.trace.put_line("Need to get a new auth token")
            if next_token then
               new_token := token
               debug
                  log.trace.put_line("**** New token is: #(1)" # new_token)
               end
               action.call([new_token.intern])
            else
               on_error.call(["Could not set auth token: #(1)" # error])
            end
         end
      ensure
         is_modified
      end

   is_modified: BOOLEAN
      do
         Result := new_token /= Void
      end

feature {}
   token: STRING
      do
         Result := vault.pass(Http_token_name)
      end

   next_token: BOOLEAN
      do
         error := vault.set_random(Http_token_name, "12an", True)
         if error.is_empty then
            error := Void
            Result := True
         end
      end

   error: ABSTRACT_STRING

feature {WEBCLIENT}
   relinquish
      require
         is_available implies is_modified
      local
         save: ABSTRACT_STRING
      do
         if is_available then
            log.trace.put_line("Closing session vault")

            if vault.is_open then
               save := vault.save
               if not save.is_empty then
                  log.warning.put_line(save)
               end
            end

            vault.close
            lock.done
            lock_file.disconnect
            is_available := False
         end
      end

   is_available: BOOLEAN

   invalidate
      do
         relinquish
         filesystem.delete(vaultpath)
      end

feature {}
   lock_vault: BOOLEAN
         -- open and lock the session vault
      local
         pg: PASS_GENERATOR; cookie: CGI_COOKIE; gen: STRING; i: INTEGER
      do
         if log.is_trace then
            log.trace.put_line("Opening session vault")
            jar.for_each(agent (c: CGI_COOKIE) do log.trace.put_line("COOKIE: #(1)=#(2)" # c.name # c.value) end(?))
         end

         cookie := jar.cookie(Session_cookie_name)
         from
            i := 3
            if cookie.value /= Void then
               vaultpath := vault_path(cookie.value)
               Result := is_valid_vaultpath(vaultpath)
               if not Result then
                  log.trace.put_line("Invalid #(1) cookie: #(2}" # Session_cookie_name # cookie.value)
               end
            end
            if Result then
               log.trace.put_line("Using #(1) cookie" # Session_cookie_name)
            else
               create pg.parse("16an")
            end
         until
            Result or else i < 0
         loop
            gen := pg.generated
            vaultpath := vault_path(gen)
            if is_valid_vaultpath(vaultpath) then
               log.trace.put_line("Deleting stale #(1) cookie: #(2)" # Session_cookie_name # gen)
               filesystem.delete(vaultpath)
               check not Result end
            else
               log.trace.put_line("Creating new #(1) cookie" # Session_cookie_name)
               cookie.value := gen
               cookie.max_age := 14400 -- 4 hours
               if webclient.script_name.is_set then
                  cookie.path := webclient.script_name.name
               end
               if webclient.server_info.is_secure then
                  cookie.secure := True
               end
               -- cookie.http_only := True
               Result := True
            end
            i := i - 1
         end
         if Result then
            lock_file := filesystem.write_text(vaultpath + ".lock")
            if lock_file /= Void then
               lock := flock.lock(lock_file)
               log.trace.put_line("Locking session vault...")
               lock.write
               log.trace.put_line("Session vault locked, may proceed")
               create vault.make(agent new_file(vaultpath, ?))
               vault.open(("#(1)!#(2)" # webclient.remote_info.user # cookie.value).out)
               Result := vault.is_open
               if Result then
                  log.trace.put_line("Session vault is open")
               else
                  log.error.put_line("Session vault is not open!")
               end
            else
               log.error.put_line("Could not connect to lock file")
               Result := False
            end
         else
            lock_file := io
            log.error.put_line("Could not create session vault")
         end
      end

   vault_path (id: ABSTRACT_STRING): STRING
      local
         xdg: XDG
      do
         Result := ("#(1)/webclient-#(2).vault" # xdg.cache_home # id).out
      end

   is_valid_vaultpath (vp: ABSTRACT_STRING): BOOLEAN
      local
         now, last_change: TIME
      do
         if filesystem.file_exists(vp) then
            last_change := filesystem.last_change_of(vp)
            now.update
            last_change.add_minute(Session_timeout_minutes)
            if last_change > now then
               Result := True
            else
               log.trace.put_line("Deleting stale #(1) cookie: #(2)" # Session_cookie_name # vp)
               filesystem.delete(vp)
            end
         end
      end

feature {}
   make (a_webclient: like webclient)
      require
         a_webclient /= Void
      do
         webclient := a_webclient
         is_available := lock_vault
      ensure
         webclient = a_webclient
      end

   new_file (file_name: ABSTRACT_STRING; master: STRING): VAULT_IO
      do
         log.info.put_line(once "Session vault file: #(1)" # file_name)
         create {ENCRYPTED_IO} Result.make(master, create {FILESYSTEM_IO}.make(file_name))
      end

   dispose
      do
         relinquish
      end

   Session_timeout_minutes: INTEGER 30
   Session_cookie_name: STRING "sessionvault"
   Http_token_name: STRING "_http_token"

   webclient: WEBCLIENT
   jar: CGI_COOKIE_JAR

   flock: FILE_LOCKER
   lock: FILE_LOCK
   lock_file: OUTPUT_STREAM

   vault: VAULT
   vaultpath: ABSTRACT_STRING

   old_token, new_token: STRING

   filesystem: FILESYSTEM

invariant
   webclient /= Void
   lock_file /= Void
   vault /= Void implies lock /= Void
   lock_file.is_connected implies lock /= Void

end -- class WEBCLIENT_SESSION
