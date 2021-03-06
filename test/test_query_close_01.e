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
class TEST_QUERY_CLOSE_01

insert
   PWD_MESSAGE_TEST

create {}
   test

feature {}
   test
      local
         q_obj, q_json: QUERY_CLOSE
      do
         create q_obj.make
         create q_json.from_json(json("{%"type%": %"query%", %"command%": %"close%"}"))
         assert(last_error = Void)
         assert(q_obj.is_equal(q_json))
      end

end -- class TEST_QUERY_CLOSE_01
