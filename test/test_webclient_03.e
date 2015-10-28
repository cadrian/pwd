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
class TEST_WEBCLIENT_03

insert
   ABSTRACT_TEST_WEBCLIENT

create {}
   make

feature {}
   make
      local
         open_form: STRING
      do
         prepare_test
         expect_splice

         open_form := "<html><head><title>test</title></head><body><h1>This is a test!</h1></body></html>%N"
         expect_read("web/templates/open_form.html", open_form)

         scenario.replay_all
         assert(call_cgi("GET", "/open").is_equal("Content-Type:text/html%R%N%
                                                  %Cache-Control:%"private,no-store,no-cache%"%R%N%
                                                  %Set-Cookie:sessionvault=AAAAAAAAAAAAAAAA; Max-Age=14400; Secure%R%N%
                                                  %%R%N%
                                                  %#(1)%R%N" # open_form))

         assert(scenario.missing_expectations.is_empty)
      end

end -- class TEST_WEBCLIENT_03
