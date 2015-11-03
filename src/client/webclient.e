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
         make as make_client
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
         cgi.run
         end_session
      end

   server_bootstrap
      do
         response_503("Server needs bootstrap; cannot access from web")
      end

   read_password_and_send_master
      do
         log.trace.put_line("Need to read master password -- sending redirect to /open")
         cgi_reply(create {CGI_RESPONSE_CLIENT_REDIRECT}.set_redirect("/open", Void))
      end

   unknown_key (key: ABSTRACT_STRING)
      do
         log.error.put_line("Unknown key: #(1) -- sending 401" + key)
         cgi_reply(create {CGI_RESPONSE_DOCUMENT}.set_status(404))
      end

   on_open
      do
         Precursor
         if open_action /= Void then
            open_action.call([])
            open_action := Void
         end
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
         path: STRING
      do
         log_query("POST")
         if path_info = Void or else path_info.segments.is_empty then
            read_password_and_send_master
         else
            path := path_info.segments.first.out
            inspect
               path
            when "vault" then
               if path_info.segments.count = 1 then
                  get_auth_token(agent post_vault(?,?))
               else
                  response_403("/vault: too many path segments")
               end
            when "pass" then
               inspect
                  path_info.segments.count
               when 1 then
                  get_auth_token(agent (auth_token, new_auth_token: FIXED_STRING)
                                    do
                                       log.trace.put_line("Server provided auth token, fetching pass list")
                                       post_pass_list(auth_token, new_auth_token)
                                    end(?, ?))
               when 2 then
                  get_auth_token(agent (key, auth_token, new_auth_token: FIXED_STRING)
                                    do
                                       log.trace.put_line("Server provided auth token, fetching pass")
                                       post_pass_key(key, auth_token, new_auth_token)
                                    end(path_info.segments.last, ?, ?))
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

feature {WEBCLIENT_SESSION}
   script_name: CGI_SCRIPT_NAME
      do
         Result := cgi.script_name
      end

   server_info: CGI_SERVER_INFO
      do
         Result := cgi.server_info
      end

   remote_info: CGI_REMOTE_INFO
      do
         Result := cgi.remote_info
      end

   path_info: CGI_PATH_INFO
      do
         Result := cgi.path_info
      end

feature {WEBCLIENT_RESOLVER}
   root: FIXED_STRING
      local
         string: STRING
      do
         Result := root_memory
         if Result = Void then
            string := ""
            if server_info.protocol /= Void then
               string.append(server_info.protocol.name)
            end
            string.append("://")
            string.append(cgi.header("HOST"))
            if script_name.is_set then
               string.extend_unless('/')
               string.append(script_name.name)
            end
            Result := string.intern
            root_memory := Result
         end
      end

feature {}
   root_memory: FIXED_STRING

   log_query (method: ABSTRACT_STRING)
      do
         log.info.put_line("#(1) [#(2)] #(3)" # method # root # (if path_info = Void then "/" else path_info.out end))
      end

   get_or_head
      local
         path: STRING
      do
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
                                        log.trace.put_line("Session vault provided auth token, responding with the open form")
                                        first_response := Void
                                        html_response("open_form.html",
                                                      create {WEBCLIENT_OPEN_FORM}.make(new_token, Current,
                                                                                        agent (key: STRING)
                                                                                           do
                                                                                              response_503("open_form: bad template key " + key)
                                                                                           end(?)))
                                     end(?))
               else
                  response_403("/open: too many path segments")
               end
            when "vault" then
               response_405("/vault: GET not supported")
            when "pass" then
               response_405("/pass: GET not supported")
            when "static" then
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

   post_vault (auth_token, new_auth_token: FIXED_STRING)
      require
         auth_token /= Void
         new_auth_token /= Void
      local
         form: CGI_FORM
      do
         create form.parse(std_input)
         if log.is_trace then
            form.form.for_each(agent (value, key: FIXED_STRING)
                                  do
                                     log.trace.put_string("Form field: ")
                                     log.trace.put_string(key)
                                     debug
                                        log.trace.put_character('=')
                                        log.trace.put_string(value)
                                     end
                                     log.trace.put_new_line
                                  end (?, ?))
         end
         if not form.form.fast_has(form_token_name) then
            response_403("/vault: missing token field")
         elseif not form.form.fast_at(form_token_name).is_equal(auth_token) then
            debug
               log.trace.put_line("'#(1)' =/= '#(2)'" # form.form.fast_at(form_token_name) # auth_token)
            end
            response_403("/vault: invalid token value")
         elseif not form.form.fast_has(form_password_name) then
            response_403("/vault: missing password name field")
         else
            first_response := Void
            master_pass.make_from_string(form.form.fast_at(form_password_name))
            open_action := agent (ot: FIXED_STRING)
                             do
                                first_response := Void
                                call_server(create {QUERY_LIST}.make, agent when_pass_list(new_auth_token, ?))
                             end(auth_token)
            send_master
         end
      end

   post_pass_list (auth_token, new_auth_token: FIXED_STRING)
      require
         auth_token /= Void
         new_auth_token /= Void
      local
         form: CGI_FORM
      do
         create form.parse(std_input)
         if not form.form.fast_has(form_token_name) then
            response_403("/pass: missing token field")
         elseif not form.form.fast_at(form_token_name).is_equal(auth_token) then
            debug
               log.trace.put_line("'#(1)' =/= '#(2)'" # form.form.fast_at(form_token_name) # auth_token)
            end
            response_403("/pass: invalid token value")
         else
            log.trace.put_line("/pass: form seems legit -- calling server with list query")
            call_server(create {QUERY_LIST}.make, agent when_pass_list(new_auth_token, ?))
         end
      end

   post_pass_key (key, auth_token, new_auth_token: FIXED_STRING)
      require
         key /= Void
         auth_token /= Void
      local
         form: CGI_FORM
      do
         create form.parse(std_input)
         if not form.form.fast_has(form_token_name) then
            response_403("/pass/*: missing token field")
         elseif not form.form.fast_at(form_token_name).is_equal(auth_token) then
            debug
               log.trace.put_line("'#(1)' =/= '#(2)'" # form.form.fast_at(form_token_name) # auth_token)
            end
            response_403("/pass: invalid token value")
         else
            do_get(key, agent when_pass_get(?, new_auth_token), agent unknown_key(?))
         end
      end

   token_name: STRING "_http_token"

   get_auth_token (action: PROCEDURE[TUPLE[FIXED_STRING, FIXED_STRING]])
      do
         start_session
         if session.is_available then
            session.get_auth_token(action, agent response_403(?))
         else
            response_403("Invalid session")
         end
      end

   next_auth_token (action: PROCEDURE[TUPLE[FIXED_STRING]])
      do
         start_session
         if session.is_available then
            session.next_auth_token(action, agent response_503(?))
         else
            response_403("Invalid session")
         end
      end

   when_pass_list (new_auth_token: FIXED_STRING; a_reply: MESSAGE)
      local
         reply: REPLY_LIST
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
               log.trace.put_line("Session vault provided auth token, responding with the pass list")
               html_response("pass_list.html",
                             create {WEBCLIENT_PASS_LIST}.make(reply, new_auth_token, Current,
                                                               agent (key: STRING)
                                                                 do
                                                                    response_503("/pass: bad template key " + key)
                                                                 end(?)))
            else
               response_503(reply.error)
            end
         else
            response_503("Unexpected server reply")
         end
      end

   when_pass_get (a_pass: STRING new_auth_token: FIXED_STRING)
      do
         log.trace.put_line("Session vault provided auth token, responding with the pass")
         html_response("pass.html",
                       create {WEBCLIENT_PASS}.make(a_pass, new_auth_token, Current,
                                                    agent (key: STRING)
                                                       do
                                                          response_503("/pass/*: bad template key " + key)
                                                       end(?)))
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
               Result.append("&lt;")
            when '>' then
               Result.append("&gt;")
            when '&' then
               Result.append("&amp;")
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
         filename: ABSTRACT_STRING
      do
         if log.is_trace then
            if template_resolver = Void then
               log.trace.put_line("html_response: static #(1)" # template_name)
            else
               log.trace.put_line("html_response: template #(1) - resolver #(2)" # template_name # template_resolver.out)
            end
         end
         if template_resolver = Void then
            filename := "#(1)/#(2)" # conf(config_static_path) # template_name
            input := filesystem.read_text(filename)
            first_response := Void
         else
            filename := "#(1)/#(2)" # conf(config_template_path) # template_name
            create {TEMPLATE_INPUT_STREAM} input.connect_to(filesystem.read_text(filename), template_resolver)
         end
         if input.is_connected then
            log.trace.put_line("Connected to file: #(1)" # filename)
            create doc.set_content_type("text/html")
            if template_resolver = Void then
               doc.set_field("Cache-Control", "private,max-age:300")
            else
               doc.set_field("Cache-Control", "private,no-store,no-cache")
            end
            if not is_head then
               extern.splice(input, doc.body)
            end
            input.disconnect
            log.trace.put_line("Replying document")
            cgi_reply(doc)
         else
            response_503("unknown file name: #(1)" # template_name)
         end
      end

   cgi_reply (r: CGI_RESPONSE)
      local
         doc: CGI_RESPONSE_DOCUMENT; fr: like first_response
      do
         if cgi.need_reply then
            if first_response /= Void then
               fr := first_response
               first_response := Void
               cgi_reply(fr)
            else
               if log.is_info then
                  if doc ?:= r then
                     doc ::= r
                     log.info.put_line("Reply document with status #(1)" # doc.status.out)
                  else
                     log.info.put_line("Reply #(1)" # r.out)
                  end
                  debug
                     if log.is_trace then
                        cgi.set_output(create {MONITORED_OUTPUT_STREAM}.connect_to(cgi.output, log.trace))
                     end
                  end
               end
               cgi.set_output(create {CRLF_OUTPUT_STREAM}.connect_to(cgi.output))
               cgi.reply(r)
               cgi.output.disconnect
            end
         elseif first_response = Void then
            log.warning.put_line("CGI does not need reply or reply already sent -- response is kept for later")
            first_response := r
         else
            log.warning.put_line("CGI does not need reply or reply already sent -- response is lost")
         end
      end

   start_session
      do
         if session = Void then
            create session.make(Current)
         end
      end

   end_session
      do
         if session /= Void then
            session.relinquish
         end
      end

   first_response: CGI_RESPONSE

feature {}
   make
      do
         create cgi.make(Current)
         make_client
      end

   cgi: CGI
   is_head: BOOLEAN

   session: WEBCLIENT_SESSION
   open_action: PROCEDURE[TUPLE]

invariant
   cgi /= Void

end -- class WEBCLIENT
