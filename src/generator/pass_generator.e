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
class PASS_GENERATOR

insert
   LOGGING
   CONFIGURABLE

create {VAULT}
   parse

create {PWD_TEST}
   test_parse

feature {ANY}
   is_valid: BOOLEAN

   generated: STRING
      require
         is_valid
      local
         bfr: BINARY_FILE_READ; rnd: PASS_GENERATOR_RANDOM
      do
         Result := ""
         create bfr.with_buffer_size(3 * length) -- 3 bytes read for each random character (two bytes to select a character, one byte to select its position)
         bfr.connect_to(random_file)
         if bfr.is_connected then
            create rnd.connect_to(bfr)
            recipe.for_each(extend.item([rnd, Result]))
            bfr.disconnect
         end
      ensure
         not Result.is_empty
      end

feature {}
   conf_random_file: FIXED_STRING
      once
         Result := "random_file".intern
      end

   default_random_file: FIXED_STRING
      once
         Result := "/dev/random".intern
      end

   recipe: FAST_ARRAY[PASS_GENERATOR_MIX]

   length: INTEGER

   random_file: FIXED_STRING

   extend: FUNCTION[TUPLE[PASS_GENERATOR_RANDOM, STRING], PROCEDURE[TUPLE[PASS_GENERATOR_MIX]]]

   default_extend (rnd: PASS_GENERATOR_RANDOM; pass: STRING): PROCEDURE[TUPLE[PASS_GENERATOR_MIX]]
      do
         Result := agent {PASS_GENERATOR_MIX}.extend(rnd, pass)
      end

   parse (a_recipe: ABSTRACT_STRING)
      require
         a_recipe /= Void
      local
         parser: PASS_GENERATOR_PARSER
      do
         create parser.parse(a_recipe)
         if parser.parsed then
            is_valid := True
            recipe := parser.recipe
            length := parser.total_quantity
            random_file := conf(conf_random_file)
            if random_file = Void then
               random_file := default_random_file
            end
            extend := agent default_extend(?, ?)
         end
      end

   test_parse (a_recipe, a_random_file: ABSTRACT_STRING; a_extend: like extend)
      require
         a_recipe /= Void
         a_random_file /= Void
         a_extend /= Void
      do
         parse(a_recipe)
         random_file := a_random_file.intern
         extend := a_extend
      ensure
         random_file = a_random_file
         extend = a_extend
      end

invariant
   is_valid implies not recipe.is_empty
   random_file /= Void
   extend /= Void

end -- class PASS_GENERATOR
