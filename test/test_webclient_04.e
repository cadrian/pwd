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
class TEST_WEBCLIENT_04

insert
   ABSTRACT_TEST_WEBCLIENT

create {}
   make

feature {}
   make
      local
         now: TIME; some_text: STRING
      do
         prepare_test

         now.update

         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_processor.split_arguments__match(create {MOCK_STREQ}.make("Test/StaticPath")).then_return({FAST_ARRAY[STRING] << "test/static" >>}),
         >>})

         some_text := "My static text"
         expect_read("test/static/some.txt", "#(1)%N" # some_text)

         expect_splice(Void, Void)

         assert(call_cgi("GET", "/static/some.txt").is_equal("Content-Type:text/html%R%N%
                                                             %Cache-Control:%"private,max-age:300%"%R%N%
                                                             %%R%N%
                                                             %#(1)%R%N" # some_text))

         assert(scenario.missing_expectations.is_empty)
      end

end -- class TEST_WEBCLIENT_04
