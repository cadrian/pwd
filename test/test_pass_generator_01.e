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
class TEST_PASS_GENERATOR_01

insert
   PWD_TEST
   PASS_GENERATOR_PARSER_CONSTANTS

create {}
   test

feature {}
   test is
      local
         gen: PASS_GENERATOR
         pass: STRING
      do
         create gen.test_parse("8a", random_file, agent extend(?, ?))
         assert(gen.is_valid)
         pass := gen.generated
         assert(pass.is_equal(password))
      end

   random_file: STRING is "pwd_test.e" -- who cares, it just needs to exist
   password: STRING is "password"

   extend (bfr: BINARY_FILE_READ; pass: STRING): PROCEDURE[TUPLE[PASS_GENERATOR_MIX]] is
      do
         assert(bfr.path.is_equal(random_file))
         assert(bfr.is_connected)
         Result := agent test_extend(?, bfr, pass)
      end

   test_extend (mix: PASS_GENERATOR_MIX; bfr: BINARY_FILE_READ; pass: STRING) is
      do
         assert(mix.quantity = 8)
         assert(mix.ingredient = letters)
         pass.append(password)
      end

end