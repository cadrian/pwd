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
class PASS_GENERATOR_MIX

insert
   LOGGING

create {PASS_GENERATOR_PARSER}
   make

feature {PASS_GENERATOR}
   extend (rnd: PASS_GENERATOR_RANDOM; pass: STRING) is
      require
         rnd.is_connected
         pass /= Void
      do
         (1 |..| quantity).do_all(agent extend_pass(rnd, pass))
      ensure
         pass.count = old pass.count + quantity
         pass.substring(old pass.lower, old pass.upper).is_equal(old pass.twin)
      end

feature {ANY}
   quantity: INTEGER_8
   ingredient: FIXED_STRING

feature {}
   extend_pass (rnd: PASS_GENERATOR_RANDOM; pass: STRING) is
      require
         rnd.is_connected
         pass /= Void
      local
         int, index: INTEGER_32
      do
         int := rnd.item(ingredient.lower, ingredient.upper)
         index := rnd.item(pass.lower, pass.upper + 1) -- extra mix
         pass.insert_character(ingredient.item(int), index)
      ensure
         pass.count = old pass.count + 1
      end

feature {}
   make (a_quantity: INTEGER; a_ingredient: like ingredient) is
      require
         a_quantity > 0
         a_quantity.fit_integer_8
         a_ingredient.count.in_range(1, 16383)
      do
         quantity := a_quantity.to_integer_8
         ingredient := a_ingredient
         log.trace.put_line(once "  ingredient: #(1) x #(2)" # a_quantity.out # a_ingredient)
      ensure
         quantity = a_quantity.to_integer_8
         ingredient = a_ingredient
      end

invariant
   quantity > 0
   ingredient.count.in_range(1, 16383)

end
