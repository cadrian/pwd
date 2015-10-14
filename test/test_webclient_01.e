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
class TEST_WEBCLIENT_01

insert
   ABSTRACT_TEST_WEBCLIENT

create {}
   make

feature {}
   make
      do
         assert(call_cgi("GET", "", Void).is_equal("Location:https://test.server.net:8943/open%R%NSet-Cookie:sessionvault=AAAAAAAAAAAAAAAA; Max-Age=14400; Secure%R%N%R%N"))

         assert(call_cgi("GET", "/", Void).is_equal("Location:https://test.server.net:8943/open%R%NSet-Cookie:sessionvault=AAAAAAAAAAAAAAAA; Max-Age=14400; Secure%R%N%R%N"))

         assert(call_cgi("GET", "/open", Void).is_equal("Content-Type:text/html%R%N%
                                                        %Cache-Control:%"private,no-store,no-cache%"%R%N%
                                                        %Set-Cookie:sessionvault=AAAAAAAAAAAAAAAA; Max-Age=14400; Secure%R%N%
                                                        %%R%N%
                                                        %<html><body></body></html>%R%N"))

         assert(call_cgi("GET", "/static/some.txt", Void).is_equal("Content-Type:text/html%R%N%
                                                                   %Cache-Control:%"private,no-store,no-cache%"%R%N%
                                                                   %Set-Cookie:sessionvault=AAAAAAAAAAAAAAAA; Max-Age=14400; Secure%R%N%
                                                                   %%R%N%
                                                                   %SOME TEXT%R%N"))


         --assert(call_cgi("GET", "/pass", "[
         --                                 {"type":"reply","command":"list","error":"","names":["foo","bar"]}
         --                                 ]").is_equal(""))
      end

end -- class TEST_WEBCLIENT_01
