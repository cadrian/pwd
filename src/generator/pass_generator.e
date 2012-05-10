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
class PASS_GENERATOR

insert
   LOGGING

create {VAULT}
   parse

feature {ANY}
   is_valid: BOOLEAN

   generated: STRING is
      require
         is_valid
      local
         bfr: BINARY_FILE_READ
      do
         Result := ""
         create bfr.with_buffer_size(3 * length) -- 3 bytes read for each random character (two bytes to select a character, one byte to select its position)
         bfr.connect_to(once "/dev/random")
         if bfr.is_connected then
            recipe.do_all(agent {PASS_GENERATOR_MIX}.extend(bfr, Result))
            bfr.disconnect
         end
      ensure
         not Result.is_empty
      end

feature {}
   recipe: FAST_ARRAY[PASS_GENERATOR_MIX]
   length: INTEGER

   parse (a_recipe: ABSTRACT_STRING) is
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
         end
      end

invariant
   is_valid implies not recipe.is_empty

end
