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
class TEST_PASS_GENERATOR_02

insert
   PWD_TEST
   PASS_GENERATOR_PARSER_CONSTANTS

create {}
   test

feature {}
   test
      local
         gen: PASS_GENERATOR; pass: STRING
      do
         create gen.test_parse("13anans+42s", random_file, agent extend(?, ?))
         assert(gen.is_valid)
         pass := gen.generated
         assert(pass.is_equal("password"))
      end

   random_file: STRING "pwd_test.e"
         -- who cares, it just needs to exist

   extend (rnd: PASS_GENERATOR_RANDOM; pass: STRING): PROCEDURE[TUPLE[PASS_GENERATOR_MIX]]
      do
         assert(rnd.path.is_equal(random_file))
         assert(rnd.is_connected)
         Result := agent test_extend(?, pass)
      end

   test_extend (mix: PASS_GENERATOR_MIX; pass: STRING)
      do
         inspect
            mix.quantity
         when 13 then
            assert(mix.ingredient = ("#(1)#(2)#(1)#(2)#(3)" # letters # figures # symbols).intern)
            pass.append("pass")
         when 42 then
            assert(mix.ingredient = symbols)
            pass.append("word")
         else
            assert(False)
         end
      end

end -- class TEST_PASS_GENERATOR_02
