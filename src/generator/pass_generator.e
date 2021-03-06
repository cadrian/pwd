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
class PASS_GENERATOR

insert
   LOGGING
   CONFIGURABLE

create {ANY}
   parse

create {PWD_TEST}
   make

feature {ANY}
   is_valid: BOOLEAN

   generated: STRING
      require
         is_valid
      local
         rnd: PASS_GENERATOR_RANDOM
      do
         Result := ""
         create rnd.connect_to(random_file)
         if rnd.is_connected then
            recipe.for_each(extend.item([rnd, Result]))
            rnd.disconnect
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
         Result := "/dev/urandom".intern
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
         rndfile: FIXED_STRING
      do
         rndfile := conf(conf_random_file)
         if rndfile = Void then
            rndfile := default_random_file
         end
         make(a_recipe, rndfile, agent default_extend(?, ?))
      end

   make (a_recipe, a_random_file: ABSTRACT_STRING; a_extend: like extend)
      require
         a_recipe /= Void
         a_random_file /= Void
         a_extend /= Void
      local
         parser: PASS_GENERATOR_PARSER
      do
         create parser.parse(a_recipe)
         if parser.parsed then
            is_valid := True
            recipe := parser.recipe
            length := parser.total_quantity
         end
         random_file := a_random_file.intern
         extend := a_extend
      ensure
         random_file = a_random_file.intern
         extend = a_extend
      end

   configuration_section: STRING "pass_generator"

invariant
   is_valid implies not recipe.is_empty
   random_file /= Void
   extend /= Void

end -- class PASS_GENERATOR
