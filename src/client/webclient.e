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
class WEBCLIENT

inherit
   CLIENT
      rename
         make as make_client,
         delete as ft_delete
      redefine
         read_password_and_send_master,
         server_bootstrap,
         on_open
      end
   CGI_HANDLER

insert
   WEBCLIENT_GLOBALS

create {EIFFELTEST_TOOLS}
   make

feature {} -- CLIENT interface
   run
      do
         if open_session_vault then
            cgi.run
         else
            response_503("Could not open session vault")
         end
      end

   open_session_vault: BOOLEAN
      local
         pg: PASS_GENERATOR; sessionvault: CGI_COOKIE; gen: STRING; ft: FILE_TOOLS; i: INTEGER
      do
         if log.is_trace then
            jar.for_each(agent (cookie: CGI_COOKIE) do log.trace.put_line("COOKIE: #(1)=#(2)" # cookie.name # cookie.value) end(?))
         end

         sessionvault := jar.cookie("sessionvault")
         from
            i := 3
            if sessionvault.value /= Void then
               vaultpath := session_vault_path(sessionvault.value)
               Result := ft.file_exists(vaultpath)
               if not Result then
                  log.trace.put_line("Invalid sessionvault cookie: " + sessionvault.value)
               end
            end
            if Result then
               log.trace.put_line("Using sessionvault cookie")
            else
               create pg.parse("16an")
            end
         until
            Result or else i < 0
         loop
            gen := pg.generated
            vaultpath := session_vault_path(gen)
            if ft.file_exists(vaultpath) then
               log.trace.put_line("Deleting stale sessionvault cookie: " + gen)
               ft.delete(vaultpath)
               check not Result end
            else
               log.trace.put_line("Creating new sessionvault cookie")
               sessionvault.value := gen
               sessionvault.max_age := 14400 -- 4 hours
               if cgi.script_name.is_set then
                  sessionvault.path := cgi.script_name.name
               end
               if cgi.server_info.is_secure then
                  sessionvault.secure := True
               end
               -- sessionvault.http_only := True
               Result := True
            end
            i := i - 1
         end
         if Result then
            create lock_file.connect_to(vaultpath + ".lock")
            if lock_file.is_connected then
               lock := flock.lock(lock_file)
               lock.write
               create session_vault.make(vaultpath)
               session_vault.open(("#(1)!#(2)" # cgi.remote_info.user # sessionvault.value).out)
               Result := session_vault.is_open
            end
         end
      end

   session_vault_path (id: ABSTRACT_STRING): STRING
      local
         xdg: XDG
      do
         Result := ("#(1)/webclient-#(2).vault" # xdg.cache_home # id).out
      end

   server_bootstrap
      do
         response_503("Server needs bootstrap; cannot access from web")
      end

   read_password_and_send_master
      do
         cgi_reply(create {CGI_RESPONSE_CLIENT_REDIRECT}.set_redirect("/open", Void))
      end

   unknown_key (key: ABSTRACT_STRING)
      do
         log.error.put_line("Unknown key: #(1)" + key)
         cgi_reply(create {CGI_RESPONSE_DOCUMENT}.set_status(404))
      end

feature {CGI_REQUEST_METHOD} -- CGI_HANDLER method
   config_template_path: FIXED_STRING
      once
         Result := ("template.path").intern
      end

   config_static_path: FIXED_STRING
      once
         Result := ("static.path").intern
      end

   get
      do
         log_query("GET")
         is_head := False
         get_or_head
      end

   head
      do
         log_query("HEAD")
         is_head := True
         get_or_head
      end

   post
      local
         path_info: CGI_PATH_INFO
         path: STRING
      do
         log_query("POST")
         path_info := cgi.path_info
         if path_info = Void or else path_info.segments.is_empty then
            read_password_and_send_master
         else
            path := path_info.segments.first.out
            inspect
               path
            when "vault" then
               if path_info.segments.count = 1 then
                  get_auth_token(agent post_vault(?))
               else
                  response_403("/vault: too many path segments")
               end
            when "pass" then
               inspect
                  path_info.segments.count
               when 1 then
                  get_auth_token(agent post_pass_list(?))
               when 2 then
                  get_auth_token(agent post_pass_key(path_info.segments.last, ?))
               else
                  response_403("/pass: too many path segments")
               end
            else
               response_403("Invalid path")
            end
         end
      end

   delete
      do
         log_query("DELETE")
         response_405("DELETE not supported")
      end

   put
      do
         log_query("PUT")
         response_405("PUT not supported")
      end

   invoke_method (a_method: FIXED_STRING)
      do
         log_query(a_method)
         response_405("#(1) not supported" # a_method)
      end

feature {WEBCLIENT_RESOLVER}
   root: FIXED_STRING
      local
         string: STRING
         sn: CGI_SCRIPT_NAME; si: CGI_SERVER_INFO
      do
         Result := root_memory
         if Result = Void then
            string := ""
            si := cgi.server_info
            if si.protocol /= Void then
               string.append(si.protocol.name)
            end
            string.append("://")
            string.append(cgi.header("HOST"))
            sn := cgi.script_name
            if sn.is_set then
               string.extend('/')
               string.append(sn.name)
            end
            Result := string.intern
            root_memory := Result
         end
      end

feature {}
   root_memory: FIXED_STRING

   log_query (method: ABSTRACT_STRING)
      local
         path_info: STRING
      do
         if cgi.path_info = Void then
            path_info := ""
         else
            path_info := cgi.path_info.out
         end
         log.info.put_line("#(1) #(2):#(3)" # method # root # path_info)
      end

   get_or_head
      local
         path_info: CGI_PATH_INFO
         path: STRING
      do
         path_info := cgi.path_info
         if path_info = Void or else path_info.segments.is_empty then
            read_password_and_send_master
         else
            path := path_info.segments.first.out
            inspect
               path
            when "" then
               read_password_and_send_master
            when "open" then
               if path_info.segments.count = 1 then
                  next_auth_token(agent (new_token: FIXED_STRING)
                                     do
                                        html_response("open_form.html",
                                                      create {WEBCLIENT_OPEN_FORM}.make(new_token, Current,
                                                                                        agent (key: STRING) do response_503("open_form: bad template key " + key) end(?)))
                                     end(?))
               else
                  response_403("/open: too many path segments")
               end
            when "vault" then
               response_405("/vault: GET not supported")
            when "pass" then
               response_405("/pass: GET not supported")
            when "static" then
               close_session_vault
               inspect
                  path_info.segments.count
               when 1 then
                  response_403("/static: too few path segments")
               when 2 then
                  html_response(path_info.segments.last, Void)
               else
                  response_403("/static: too many path segments")
               end
            else
               response_403("Invalid path")
            end
         end
      end

   post_vault (auth_token: FIXED_STRING)
      require
         auth_token /= Void
      local
         form: CGI_FORM
      do
         create form.parse(std_input)
         if log.is_trace then
            form.form.for_each(agent (value, key: FIXED_STRING)
                                  do
                                     log.trace.put_string("Form field: ")
                                     log.trace.put_line(key)
                                  end (?, ?))
         end
         if not form.form.fast_has(form_token_name) then
            response_403("Missing token field")
         elseif not form.form.fast_at(form_token_name).is_equal(auth_token) then
            log.trace.put_line("#(1) =/= #(2)" # form.form.fast_at(form_token_name) # auth_token)
            response_403("Invalid token value")
         elseif not form.form.fast_has(form_password_name) then
            response_403("Missing password name field")
         else
            master_pass.make_from_string(form.form.fast_at(form_password_name))
            send_master
         end
      end

   on_open
      local
         auth_token: STRING
      do
         log.info.put_line(once "Server vault is open")
         auth_token := session_vault.pass(token_name)
         if auth_token = Void then
            cgi_reply(create {CGI_RESPONSE_LOCAL_REDIRECT}.set_redirect("/open", Void))
         else
            call_server(create {QUERY_LIST}.make, agent when_pass_list(auth_token.intern, ?))
         end
      end

   post_pass_list (auth_token: FIXED_STRING)
      require
         auth_token /= Void
      local
         form: CGI_FORM
      do
         create form.parse(std_input)
         if not form.form.fast_has(form_token_name) then
            response_403("Missing token field")
         elseif form.form.fast_at(form_token_name).is_equal(auth_token) then
            response_403("Invalid token value")
         else
            call_server(create {QUERY_LIST}.make, agent when_pass_list(auth_token, ?))
         end
      end

   post_pass_key (key, auth_token: FIXED_STRING)
      require
         key /= Void
         auth_token /= Void
      local
         form: CGI_FORM
      do
         create form.parse(std_input)
         if not form.form.fast_has(form_token_name) then
            response_403("Missing token field")
         elseif form.form.fast_at(form_token_name).is_equal(auth_token) then
            response_403("Invalid token name")
         else
            do_get(key, agent when_pass_get(?), agent unknown_key(?))
         end
      end

   token_name: STRING "_http_token"

   get_auth_token (action: PROCEDURE[TUPLE[FIXED_STRING, FIXED_STRING]])
         -- action takes the old and new auth tokens
      local
         old_token: STRING
      do
         old_token := session_vault.pass(token_name)
         if old_token /= Void then
            log.trace.put_line("Old token was: #(1)" # old_token)
            --|**** TODO (Liberty Eiffel) I would have liked to write:
            -- next_auth_token(agent action(old_token, ?))
            next_auth_token(agent (ot, nt: FIXED_STRING) do action(ot, nt) end(old_token.intern, ?))
         else
            response_403("Old token not found")
         end
      end

   next_auth_token (action: PROCEDURE[TUPLE[FIXED_STRING]])
         -- action takes the new auth token
      local
         error: ABSTRACT_STRING; new_token: STRING
      do
         error := session_vault.set_random(token_name, "12an")
         if error.is_empty then
            new_token := session_vault.pass(token_name)
            log.trace.put_line("New token is: #(1)" # new_token)
            action(new_token.intern)
         else
            response_503("Could not set auth token: #(1)" # error)
         end
      end

   when_pass_list (auth_token: FIXED_STRING; a_reply: MESSAGE)
      local
         reply: REPLY_LIST
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
               html_response("pass_list.html",
                             create {WEBCLIENT_PASS_LIST}.make(reply, auth_token, Current,
                                                               agent (key: STRING) do response_503("pass_list: bad template key " + key) end(?)))
            else
               response_503(reply.error)
            end
         else
            response_503("Unexpected server reply")
         end
      end

   when_pass_get (a_pass: STRING)
      do
         next_auth_token(agent (new_token: FIXED_STRING)
                            do
                               html_response("pass.html",
                                             create {WEBCLIENT_PASS}.make(a_pass, new_token, Current,
                                                                          agent (key: STRING) do response_503("pass: bad template key " + key) end(?)))
                            end(?))
      end

   protect_html (a_data: ABSTRACT_STRING): STRING
      local
         i: INTEGER; c: CHARACTER
      do
         from
            Result := ""
            i := a_data.lower
         until
            i > a_data.upper
         loop
            c := a_data.item(i)
            inspect
               c
            when '<' then
               Result.append(once "&lt;")
            when '>' then
               Result.append(once "&gt;")
            when '&' then
               Result.append(once "&amp;")
            else
               Result.extend(c)
            end
            i := i + 1
         end
      end

   response_403 (message: ABSTRACT_STRING)
      do
         log.error.put_line(message)
         cgi_reply(create {CGI_RESPONSE_DOCUMENT}.set_status(403))
      end

   response_405 (message: ABSTRACT_STRING)
      do
         log.error.put_line(message)
         cgi_reply(create {CGI_RESPONSE_DOCUMENT}.set_status(405))
      end

   response_503 (message: ABSTRACT_STRING)
      do
         log.error.put_line(message)
         cgi_reply(create {CGI_RESPONSE_DOCUMENT}.set_status_and_error(503, message))
      end

   html_response (template_name: ABSTRACT_STRING; template_resolver: TEMPLATE_RESOLVER)
      require
         template_name /= Void
      local
         doc: CGI_RESPONSE_DOCUMENT
         extern: EXTERN
         input: INPUT_STREAM
      do
         if log.is_trace then
            if template_resolver = Void then
               log.trace.put_line("html_response: static #(1)" # template_name)
            else
               log.trace.put_line("html_response: template #(1) - resolver #(2)" # template_name # template_resolver.out)
            end
         end
         if template_resolver = Void then
            create {TEXT_FILE_READ} input.connect_to("#(1)/#(2)" # conf(config_static_path) # template_name)
         else
            create {TEMPLATE_INPUT_STREAM} input.connect_to(create {TEXT_FILE_READ}.connect_to("#(1)/#(2)" # conf(config_template_path) # template_name), template_resolver)
         end
         if input.is_connected then
            create doc.set_content_type("text/html")
            doc.set_field("Cache-Control", "private,no-store,no-cache")
            if not is_head then
               extern.splice(input, doc.body)
            end
            input.disconnect
            cgi_reply(doc)
         else
            response_503("unknown file name: #(1)" # template_name)
         end
      end

   cgi_reply (r: CGI_RESPONSE)
      local
         doc: CGI_RESPONSE_DOCUMENT; save: ABSTRACT_STRING
      do
         if cgi.need_reply then
            if log.is_info then
               if doc ?:= r then
                  doc ::= r
                  log.info.put_line("Reply document with status #(1)" # doc.status.out)
               else
                  log.info.put_line("Reply #(1)" # r.out)
               end
               if log.is_trace then
                  cgi.set_output(create {MONITORED_OUTPUT_STREAM}.connect_to(cgi.output, log.trace))
               end
            end
            cgi.set_output(create {CRLF_OUTPUT_STREAM}.connect_to(cgi.output))
            cgi.reply(r)
            cgi.output.disconnect
            if session_vault.is_open then
               save := session_vault.save
               if not save.is_empty then
                  log.warning.put_line(save)
               end
               close_session_vault
            end
         end
      end

   close_session_vault
      do
         session_vault.close
         lock.done
         lock_file.disconnect
      end

feature {}
   make
      do
         create cgi.make(Current)
         make_client
      end

   cgi: CGI
   is_head: BOOLEAN

   session_vault: VAULT
   vaultpath: ABSTRACT_STRING

   jar: CGI_COOKIE_JAR

   flock: FILE_LOCKER
   lock: FILE_LOCK
   lock_file: TEXT_FILE_WRITE

invariant
   cgi /= Void
   session_vault /= Void implies lock /= Void
   lock /= Void implies lock_file /= Void
   lock.locked implies lock_file.is_connected

end -- class WEBCLIENT
