-- This file is part of pwdmgr.
-- Copyright (C) 2012 Cyril Adrian <cyril.adrian@gmail.com>
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
   extend (file: POINTER; pass: STRING) is
      require
         not file.is_default
         pass /= Void
      do
         (1 |..| quantity).do_all(agent extend_pass(file, pass))
      ensure
         pass.count = old pass.count + quantity
         pass.substring(old pass.lower, old pass.upper).is_equal(old pass.twin)
      end

feature {}
   quantity: INTEGER
   ingredient: FIXED_STRING

feature {}
   extend_pass (file: POINTER; pass: STRING) is
      require
         not file.is_default
         pass /= Void
      local
         int: INTEGER_32
      do
         c_inline_c("_int=(((int)io_getc((FILE*)a1) & 0x7f) << 8) | (int)io_getc((FILE*)a1);%N") -- >>
         pass.extend(ingredient.item(int \\ ingredient.count + ingredient.lower))
      ensure
         pass.count = old pass.count + 1
      end

feature {}
   make (a_quantity: like quantity; a_ingredient: like ingredient) is
      require
         a_quantity > 0
         a_ingredient.count.in_range(1, 16383)
      do
         quantity := a_quantity
         ingredient := a_ingredient
         log.trace.put_line(once "  ingredient: #(1) x #(2)" # a_quantity.out # a_ingredient)
      ensure
         quantity = a_quantity
         ingredient = a_ingredient
      end

invariant
   quantity > 0
   ingredient.count.in_range(1, 16383)

end
