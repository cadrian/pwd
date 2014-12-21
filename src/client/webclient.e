-- This file is part of pwd.
-- Copyright (C) 2012-2014 Cyril Adrian <cyril.adrian@gmail.com>
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

   config_template_path: FIXED_STRING
      once
         Result := ("template.path").intern
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
      local
         path: STRING
      do
         if cgi.path_info.segments.is_empty then
            response_403
         else
            path := cgi.path_info.segments.first.out
            inspect
               path
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
      local
         path: STRING
      do
         if cgi.path_info.segments.is_empty then
            read_password_and_send_master
         else
            path := cgi.path_info.segments.first.out
            inspect
               path
            when "open" then
               if cgi.path_info.segments.count = 1 then
                  --|**** TODO: potential DOS :-(
                  next_auth_token(agent (auth_token: STRING)
                                  require
                                     auth_token /= Void
                                  do
                                     html_response("open_form.html",
                                                   agent (key: STRING): ABSTRACT_STRING
                                                      require
                                                         key /= Void
                                                      do
                                                         inspect
                                                            key
                                                         when "form_token_name" then
                                                            Result := form_token_name
                                                         when "form_password_name" then
                                                            Result := form_password_name
                                                         when "auth_token" then
                                                            Result := auth_token
                                                         else
                                                            response_503("bad template key")
                                                         end
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
               html_response("pass_list.html",
                             agent (key: STRING; rl: REPLY_LIST): STRING
                             require
                                key /= Void
                             do
                                inspect
                                   key
                                when "pass_list" then
                                   Result := ""
                                   rl.for_each_name(agent (name, res: STRING)
                                                    do
                                                       res.append("<li><a href=%"#(1)/#(2)%">#(2)</a></li>%N"
                                                          # (if cgi.script_name.is_set then "/" + cgi.script_name.name else "" end)
                                                          # name
                                                       )
                                                    end(?, Result))
                                else
                                   response_503("bad template key")
                                end
                             end(?, reply))
            else
               response_503(reply.error)
            end
         else
            response_503("Unexpected server reply")
         end
      end

   when_pass_get (a_pass: STRING)
      do
         html_response("pass.html",
                       agent (key: STRING): STRING
                       require
                          key /= Void
                       do
                          inspect
                             key
                          when "pass" then
                             Result := a_pass
                          else
                             response_503("bad template key")
                          end
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

   html_response (template_name: ABSTRACT_STRING; template_resolver: FUNCTION[TUPLE[STRING], ABSTRACT_STRING])
      local
         doc: CGI_RESPONSE_DOCUMENT
         path: ABSTRACT_STRING
         tis: TEMPLATE_INPUT_STREAM
      do
         path := "#(1)/#(2)" # conf(config_template_path) # template_name
         create tis.connect_to(create {TEXT_FILE_READ}.connect_to(path), template_resolver)
         if tis.is_connected then
            create doc.set_content_type("text/html")
            doc.set_field("Cache-Control", "private,no-store,no-cache")
            if not is_head then
               from
                  tis.read_character
               until
                  tis.end_of_input
               loop
                  doc.body.put_character(tis.last_character)
                  tis.read_character
               end
            end
            tis.disconnect
            if cgi.need_reply then
               cgi.reply(doc)
            end
         else
            response_503("bad template name")
         end
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
