-- This file is part of pwdmgr.
-- Copyright (C) 2012-2014 Cyril Adrian <cyril.adrian@gmail.com>
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
class WEBCLIENT

inherit
   CLIENT
      rename
         make as make_client,
         delete as ft_delete
      redefine
         read_password_and_send_master,
         server_bootstrap,
         when_master
      end
   CGI_HANDLER

create {}
   make

feature {} -- CLIENT interface
   run
      do
         cgi.run
      end

   server_bootstrap
      do
         response_503("Server needs bootstrap; cannot access from web")
      end

   read_password_and_send_master
      do
         cgi.reply(create {CGI_RESPONSE_LOCAL_REDIRECT}.set_redirect("/open", Void))
      end

   unknown_key (key: ABSTRACT_STRING)
      do
         cgi.reply(create {CGI_RESPONSE_DOCUMENT}.set_status(404))
      end

feature {CGI_REQUEST_METHOD} -- CGI_HANDLER method
   form_token_name: FIXED_STRING
      once
         Result := "token".intern
      end

   form_password_name: FIXED_STRING
      once
         Result := "password".intern
      end

   get
      do
         is_head := False
         get_or_head
      end

   head
      do
         is_head := True
         get_or_head
      end

   post
      do
         if cgi.path_info.segments.is_empty then
            response_403
         else
            inspect
               cgi.path_info.segments.first.out
            when "vault" then
               if cgi.path_info.segments.count = 1 then
                  get_auth_token(agent (auth_token: STRING)
                                 require
                                    auth_token /= Void
                                 local
                                    form: CGI_FORM
                                 do
                                    create form.parse(std_input)
                                    if form.form.fast_has(form_token_name) and then form.form.fast_at(form_token_name).is_equal(auth_token) and then form.form.fast_has(form_password_name) then
                                       master_pass.make_from_string(form.form.fast_at(form_password_name))
                                       send_master
                                    else
                                       response_403
                                    end
                                 end(?))
               else
                  response_403
               end
            else
               response_403
            end
         end
      end

   delete
      do
         cgi.reply(create {CGI_RESPONSE_DOCUMENT}.set_status(405))
      end

   put
      do
         cgi.reply(create {CGI_RESPONSE_DOCUMENT}.set_status(405))
      end

   invoke_method (a_method: FIXED_STRING)
      do
         cgi.reply(create {CGI_RESPONSE_DOCUMENT}.set_status(405))
      end

feature {}
   get_or_head
      do
         if cgi.path_info.segments.is_empty then
            read_password_and_send_master
         else
            inspect
               cgi.path_info.segments.first.out
            when "open" then
               if cgi.path_info.segments.count = 1 then
                  next_auth_token(agent (auth_token: STRING) --| **** TODO: potential DOS :-(
                                  require
                                     auth_token /= Void
                                  do
                                     html_response(agent (doc: CGI_RESPONSE_DOCUMENT)
                                                   require
                                                      doc /= Void
                                                   do
                                                      doc.body.put_string("[
                                                                              <html>
                                                                                 <head>
                                                                                    <title>CAD's password vault</title>
                                                                                 </head>
                                                                                 <body>
                                                                                    <h2>Vault password</h2>
                                                                                    <form method="post" action="/auth">
                                                                                       <input type="hidden" name="#(2)" value="#(1)" />
                                                                                       <input type="password" name="#(3)" />
                                                                                       <input type="submit" value="OK">
                                                                                    </form>
                                                                                 </body>
                                                                              </html>
                                                                           ]"
                                                                              # auth_token
                                                                              # form_token_name
                                                                              # form_password_name)
                                                   end(?))
                                  end(?))
               end
            when "auth" then
               cgi.reply(create {CGI_RESPONSE_DOCUMENT}.set_status(405))
            when "pass" then
               inspect
                  cgi.path_info.segments.count
               when 1 then
                  call_server(create {QUERY_LIST}.make, agent when_pass_list(?))
               when 2 then
                  do_get(cgi.path_info.segments.last, agent when_pass_get(?), agent unknown_key(?))
               else
                  response_403
               end
            else
               response_403
            end
         end
      end

   token_name: STRING "_http_token"

   get_auth_token (action: PROCEDURE[TUPLE[STRING]])
      do
         do_get(token_name, action,
                agent (a_token_name: ABSTRACT_STRING)
                   do
                      check a_token_name = token_name end
                      response_403
                   end(?))
      end

   next_auth_token (action: PROCEDURE[TUPLE[STRING]])
      local
         query: QUERY_SET
      do
         create query.make_random(token_name, "12an")
         call_server(query, agent when_next_token(action, ?))
      end

   when_next_token (action: PROCEDURE[TUPLE[STRING]]; a_reply: MESSAGE)
      local
         reply: REPLY_SET
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
               action(reply.pass)
            else
               response_503(reply.error)
            end
         else
            response_503("Unexpected server reply")
         end
      end

   when_master (a_reply: MESSAGE)
      local
         reply: REPLY_MASTER
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
               cgi.reply(create {CGI_RESPONSE_LOCAL_REDIRECT}.set_redirect("/pass", Void))
            else
               response_403
            end
         else
            response_403
         end
      end

   when_pass_list (a_reply: MESSAGE)
      local
         reply: REPLY_LIST
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
               html_response(agent (doc: CGI_RESPONSE_DOCUMENT)
                             require
                                doc /= Void
                             do
                                doc.body.put_line("<html><head><title>CAD's password vault list</title></head><body><ul>")
                                reply.for_each_name(agent (name: STRING)
                                                    do
                                                       doc.body.put_line("<li><a href=%"#(1)/#(2)%">#(2)</a></li>"
                                                          # (if cgi.script_name.is_set then "/" + cgi.script_name.name else "" end)
                                                          # name
                                                       )
                                                    end(?))
                                doc.body.put_line("</ul></body></html>")
                             end(?))
            else
               response_503(reply.error)
            end
         else
            response_503("Unexpected server reply")
         end
      end

   when_pass_get (a_pass: STRING)
      do
         html_response(agent (doc: CGI_RESPONSE_DOCUMENT)
                       require
                          doc /= Void
                       do
                          doc.body.put_line("[
                                                <html>
                                                   <head>
                                                      <title>CAD's password vault pass</title>
                                                      <script language="JavaScript">
                                                         function copy() {
                                                            holdtext.innerText = copytext.innerText;
                                                            Copied = holdtext.createTextRange();
                                                            Copied.execCommand("Copy");
                                                         }
                                                      </script>
                                                   </head>
                                                   <body>
                                                      <span id="copytext" style="display:none;">#(1)</span>
                                                      <textarea id="holdtext" style="display:none;"></textarea>
                                                      <button onClick="copy();">Copy</button>
                                                   </body>
                                                </html>
                                             ]" # protect_html(a_pass))
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

   response_403
      do
         cgi.reply(create {CGI_RESPONSE_DOCUMENT}.set_status(403))
      end

   response_503 (message: ABSTRACT_STRING)
      do
         cgi.reply(create {CGI_RESPONSE_DOCUMENT}.set_status_and_error(503, message))
      end

   html_response (fill_body: PROCEDURE[TUPLE[CGI_RESPONSE_DOCUMENT]])
      local
         doc: CGI_RESPONSE_DOCUMENT
      do
         create doc.set_content_type("text/html")
         doc.set_field("Cache-Control", "private,no-store,no-cache")
         if not is_head then
            fill_body(doc)
         end
         cgi.reply(doc)
      end

feature {}
   make
      do
         create cgi.make(Current)
         make_client
      end

   cgi: CGI
   is_head: BOOLEAN

invariant
   cgi /= Void

end -- class WEBCLIENT
