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
         make as make_client
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
         create {CGI_RESPONSE_LOCAL_REDIRECT} response.set_redirect("/open")
      end

   unknown_key (key: ABSTRACT_STRING)
      do
         create {CGI_RESPONSE_DOCUMENT} response.set_status(204)
      end

   response: CGI_RESPONSE

feature {CGI_REMOTE_METHOD} -- CGI_HANDLER method
   get: CGI_RESPONSE
      local
         doc: CGI_RESPONSE_DOCUMENT
      do
         inspect
            cgi.path_info.segments.first.out
         when "open" then
            if cgi.path_info.segments.count = 1 then
               next_auth_token --| **** TODO: potential DOS :-(
               create doc.set_content_type("text/html")
               doc.body.put_string("[
                                       <html>
                                          <head>
                                             <title>CAD's password vault</title>
                                          </head>
                                          <body>
                                             <h2>Vault password</h2>
                                             <form method="post" action="/auth">
                                                <input type="hidden" name="token" value="#(1)" />
                                                <input type="password" name="password" />
                                                <input type="submit" value="OK">
                                             </form>
                                          </body>
                                       </html>
                                    ]"
                                       # auth_token)
            end
         when "auth" then
            create doc.set_status(405)
         when "pass" then
            inspect
               cgi.path_info.segments.count
            when 1 then
               call_server(create {QUERY_LIST}.make, agent when_pass_list(?))
            when 2 then
               get_back(cgi.path_info.segments.last, agent when_pass_get(?), agent unknown_key(?))
            else
            end
         else
         end
         if response = Void then
            if doc = Void then
               create doc.set_status(404)
            end
            response := doc
         end
         Result := response
      end

   post: CGI_RESPONSE
      local
         form: CGI_FORM; token: FIXED_STRING
      do
         inspect
            cgi.path_info.segments.first.out
         when "vault" then
            if cgi.path_info.segments.count = 1 then
               get_auth_token
               if auth_token /= Void then
                  create form.parse(std_input)
                  if form.form.has("token") and then form.form.at("token").is_equal(auth_token) and then form.form.has("password") then
                     master_pass.make_from_string(form.form.at("password"))
                     send_master
                  else
                     response_403
                  end
               else
                  response_403
               end
            else
               response_403
            end
         else
            response_403
         end
         Result := response
      end

   head: CGI_RESPONSE
      do
         create {CGI_RESPONSE_DOCUMENT} Result.set_status(404)
      end

   delete: CGI_RESPONSE
      do
         create {CGI_RESPONSE_DOCUMENT} Result.set_status(405)
      end

   put: CGI_RESPONSE
      do
         create {CGI_RESPONSE_DOCUMENT} Result.set_status(405)
      end

   invoke_method (a_method: FIXED_STRING): CGI_RESPONSE
      do
         create {CGI_RESPONSE_DOCUMENT} Result.set_status(405)
      end

feature {}
   auth_token: STRING

   token_name: STRING "_http_token"

   get_auth_token
      do
         do_get(token_name,
                agent (token: STRING)
                   do
                      auth_token := token
                      --| **** TODO: potential DOS? call_server(create {QUERY_UNSET}.make(token_name), agent (reply: MESSAGE) do end(?))
                   end(?),
                agent (token: STRING)
                   do
                      auth_token := Void
                   end(?))
      end

   next_auth_token
      local
         query: QUERY_SET
      do
         create query.make_random(token_name, "12an")
         call_server(query, agent when_next_token(?))
      end

   when_next_token (a_reply: MESSAGE)
      local
         reply: REPLY_SET
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
               auth_token := reply.pass
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
               create {CGI_RESPONSE_LOCAL_REDIRECT} response.set_redirect("/pass")
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
         doc: CGI_RESPONSE_DOCUMENT
      do
         if reply ?:= a_reply then
            reply ::= a_reply
            if reply.error.is_empty then
               create doc.set_content_type("text/html")
               doc.body.put_line("<html><head><title>CAD's password vault list</title></head><body><ul>")
               reply.for_each_name(agent (name: STRING)
                                   do
                                      doc.body.put_line("<li><a href=%"#(1)/#(2)%">#(2)</a></li>"
                                         # (if cgi.script_name = Void then "" else "/" + cgi.script_name.name end)
                                         # name
                                      )
                                   end(?))
               doc.body.put_line("</ul></body></html>")
            else
               response_503(reply.error)
            end
         else
            response_503("Unexpected server reply")
         end
      end

   when_pass_get (a_pass: STRING)
      local
         doc: CGI_RESPONSE_DOCUMENT
      do
         create doc.set_content_type("text/html")
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
      end

   protect_html (data: ABSTRACT_STRING): STRING
      local
         i: INTEGER; c: CHARACTER
      do
         from
            Result := ""
            i := data.lower
         until
            i > data.upper
         loop
            c := data.item(i)
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
         create {CGI_RESPONSE_DOCUMENT} response.set_status(403)
      end

   response_503 (message: ABSTRACT_STRING)
      do
         create {CGI_RESPONSE_DOCUMENT} response.set_status_and_error(503, message)
      end

feature {}
   make
      do
         create cgi.make(Current)
         make_client
      end

   cgi: CGI

end -- class WEBCLIENT
